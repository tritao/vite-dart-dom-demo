part of "solid.dart";

typedef Dispose = void Function();
typedef Cleanup = void Function();
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);

abstract class Disposable {
  void dispose();
}

final class Owner implements Disposable {
  Owner(this.parent);

  final Owner? parent;
  final List<Cleanup> _cleanups = <Cleanup>[];
  final List<Disposable> _owned = <Disposable>[];
  ErrorHandler? _errorHandler;
  bool _disposed = false;

  bool get disposed => _disposed;

  ErrorHandler? get errorHandler => _errorHandler ?? parent?.errorHandler;

  void setErrorHandler(ErrorHandler handler) {
    _errorHandler = handler;
  }

  void _own(Disposable disposable) {
    if (_disposed) {
      disposable.dispose();
      return;
    }
    _owned.add(disposable);
  }

  void _addCleanup(Cleanup cleanup) {
    if (_disposed) {
      try {
        cleanup();
      } catch (_) {}
      return;
    }
    _cleanups.add(cleanup);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final disposable in _owned.reversed) {
      try {
        disposable.dispose();
      } catch (_) {}
    }
    _owned.clear();

    for (final cleanup in _cleanups.reversed) {
      try {
        cleanup();
      } catch (_) {}
    }
    _cleanups.clear();
  }
}

Owner? _currentOwner;
Computation? _currentComputation;
int _batchDepth = 0;
bool _flushScheduled = false;
final Set<Computation> _queue = <Computation>{};
ErrorHandler? _globalErrorHandler;

void setGlobalErrorHandler(ErrorHandler handler) {
  _globalErrorHandler = handler;
}

void clearGlobalErrorHandler() {
  _globalErrorHandler = null;
}

/// Sets an error handler scoped to the current owner/root.
///
/// This overrides the global error handler for computations created under the
/// same owner subtree.
void setErrorHandler(ErrorHandler handler) {
  final owner = _currentOwner;
  if (owner == null) {
    throw StateError("setErrorHandler() called with no active owner");
  }
  owner.setErrorHandler(handler);
}

T createRoot<T>(T Function(Dispose dispose) fn) {
  final previous = _currentOwner;
  final owner = Owner(previous);
  _currentOwner = owner;

  final Dispose dispose = owner.dispose;
  try {
    return fn(dispose);
  } finally {
    _currentOwner = previous;
  }
}

/// Creates a disposable child scope under the current owner.
///
/// Use this to model component/subtree lifetimes. Disposing the returned handle
/// disposes everything created within [fn], without affecting the parent owner.
T createChildRoot<T>(T Function(Dispose dispose) fn) {
  final parent = _currentOwner;
  if (parent == null) {
    throw StateError("createChildRoot() called with no active owner");
  }
  final previous = _currentOwner;
  final owner = Owner(parent);
  parent._own(owner);
  _currentOwner = owner;

  final Dispose dispose = owner.dispose;
  try {
    return fn(dispose);
  } finally {
    _currentOwner = previous;
  }
}

void onCleanup(Cleanup cleanup) {
  final computation = _currentComputation;
  if (computation != null) {
    computation._addCleanup(cleanup);
    return;
  }
  final owner = _currentOwner;
  if (owner == null) {
    throw StateError("onCleanup() called with no active owner");
  }
  owner._addCleanup(cleanup);
}

T untrack<T>(T Function() fn) {
  final previous = _currentComputation;
  _currentComputation = null;
  try {
    return fn();
  } finally {
    _currentComputation = previous;
  }
}

void batch(void Function() fn) {
  _batchDepth++;
  try {
    fn();
  } finally {
    _batchDepth--;
    if (_batchDepth == 0) {
      _flushSync();
    }
  }
}

void _enqueue(Computation computation) {
  if (computation._disposed) return;
  if (!computation._queued) {
    computation._queued = true;
    _queue.add(computation);
  }

  if (_batchDepth > 0) return;
  if (_flushScheduled) return;
  _flushScheduled = true;
  scheduleMicrotask(() {
    _flushScheduled = false;
    _flushSync();
  });
}

void _flushSync() {
  if (_queue.isEmpty) return;
  while (_queue.isNotEmpty) {
    final batch = _queue.toList(growable: false);
    _queue.clear();
    for (final computation in batch) {
      computation._queued = false;
      try {
        computation._run();
      } catch (e, st) {
        _reportError(computation._owner, e, st);
      }
    }
  }
}

void _reportError(Owner? owner, Object error, StackTrace stackTrace) {
  final handler = owner?.errorHandler ?? _globalErrorHandler;
  if (handler != null) {
    try {
      handler(error, stackTrace);
      return;
    } catch (_) {
      // fall through to throwing original error
    }
  }
  Zone.current.handleUncaughtError(error, stackTrace);
}

void _maybeReportError(Owner? owner, Object error, StackTrace stackTrace) {
  final handler = owner?.errorHandler ?? _globalErrorHandler;
  if (handler == null) return;
  try {
    handler(error, stackTrace);
  } catch (_) {}
}

abstract class Dependency {
  void _subscribe(Computation computation);
  void _unsubscribe(Computation computation);
}

final class Computation implements Disposable {
  Computation._(
    this._fn,
    this._owner, {
    required this.isMemo,
    bool autoRun = true,
  }) {
    _owner._own(this);
    if (autoRun) _run();
  }

  final Owner _owner;
  final bool isMemo;
  void Function() _fn;

  final Set<Dependency> _deps = <Dependency>{};
  final List<Cleanup> _cleanups = <Cleanup>[];

  bool _disposed = false;
  bool _running = false;
  bool _queued = false;

  void _addCleanup(Cleanup cleanup) => _cleanups.add(cleanup);

  void _track(Dependency dependency) {
    if (_deps.add(dependency)) dependency._subscribe(this);
  }

  void _clearDeps() {
    for (final dep in _deps) {
      dep._unsubscribe(this);
    }
    _deps.clear();
  }

  void _cleanup() {
    if (_cleanups.isEmpty) return;
    for (final cleanup in _cleanups.reversed) {
      try {
        cleanup();
      } catch (_) {}
    }
    _cleanups.clear();
  }

  void _markStale() => _enqueue(this);

  void _run() {
    if (_disposed) return;
    if (_running) {
      throw StateError("Computation re-entered while already running");
    }
    _running = true;

    final previous = _currentComputation;
    _currentComputation = this;

    _clearDeps();
    _cleanup();

    try {
      _fn();
    } finally {
      _currentComputation = previous;
      _running = false;
    }
  }

  void _setFn(void Function() fn, {bool runNow = false}) {
    _fn = fn;
    if (runNow) _run();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearDeps();
    _cleanup();
  }
}
