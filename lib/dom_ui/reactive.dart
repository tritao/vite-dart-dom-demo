import 'dart:async';

typedef Cleanup = void Function();
typedef EffectFn = Cleanup? Function();

abstract class Disposable {
  void dispose();
}

abstract class _Observable {
  final Set<_Observer> _subscribers = <_Observer>{};

  void _subscribe(_Observer observer) => _subscribers.add(observer);
  void _unsubscribe(_Observer observer) => _subscribers.remove(observer);

  void _notify() {
    if (_subscribers.isEmpty) return;
    for (final observer in _subscribers.toList(growable: false)) {
      observer._onDependencyChanged();
    }
  }
}

mixin _Observer {
  final Set<_Observable> _deps = <_Observable>{};

  void _track(_Observable observable) {
    if (_deps.add(observable)) {
      observable._subscribe(this);
    }
  }

  void _clearDeps() {
    if (_deps.isEmpty) return;
    for (final dep in _deps) {
      dep._unsubscribe(this);
    }
    _deps.clear();
  }

  void _onDependencyChanged();
}

_Observer? _currentObserver;

T _withObserver<T>(_Observer observer, T Function() fn) {
  final previous = _currentObserver;
  _currentObserver = observer;
  try {
    return fn();
  } finally {
    _currentObserver = previous;
  }
}

final class Signal<T> extends _Observable {
  Signal(this._value);

  T _value;

  T get value {
    final observer = _currentObserver;
    if (observer != null) observer._track(this);
    return _value;
  }

  set value(T next) {
    if (_value == next) return;
    _value = next;
    _notify();
  }

  void update(T Function(T current) fn) => value = fn(value);
}

final class Computed<T> extends _Observable
    with _Observer
    implements Disposable {
  Computed(this._compute) : _dirty = true;

  T Function() _compute;
  bool _dirty;
  bool _computing = false;
  T? _cached;
  bool _disposed = false;

  T get value {
    if (_disposed) {
      throw StateError('Computed was disposed');
    }

    final observer = _currentObserver;
    if (observer != null) observer._track(this);

    if (_dirty) _recompute();
    return _cached as T;
  }

  void updateCompute(T Function() compute) {
    if (_disposed) return;
    _compute = compute;
    _markDirtyAndNotify();
  }

  void _recompute() {
    if (_computing) {
      throw StateError('Computed recomputed while already computing');
    }
    _computing = true;
    _clearDeps();
    try {
      final next = _withObserver<T>(this, _compute);
      _cached = next;
      _dirty = false;
    } finally {
      _computing = false;
    }
  }

  void _markDirtyAndNotify() {
    if (_dirty) return;
    _dirty = true;
    _notify();
  }

  @override
  void _onDependencyChanged() {
    if (_disposed) return;
    _markDirtyAndNotify();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearDeps();
    _subscribers.clear();
  }
}

final class EffectHandle with _Observer implements Disposable {
  EffectHandle._(this._fn) {
    _run();
  }

  EffectFn _fn;
  Cleanup? _cleanup;
  bool _scheduled = false;
  bool _disposed = false;

  void update(EffectFn fn, {bool runNow = false}) {
    if (_disposed) return;
    _fn = fn;
    if (runNow) {
      _run();
    }
  }

  void _schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      _run();
    });
  }

  void _run() {
    if (_disposed) return;
    _clearDeps();
    try {
      _cleanup?.call();
    } catch (_) {}
    _cleanup = null;

    try {
      _cleanup = _withObserver<Cleanup?>(this, _fn);
    } catch (_) {
      _cleanup = null;
    }
  }

  @override
  void _onDependencyChanged() => _schedule();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearDeps();
    try {
      _cleanup?.call();
    } catch (_) {}
    _cleanup = null;
  }
}

EffectHandle effect(EffectFn fn) => EffectHandle._(fn);
