import 'dart:js_interop';
import 'dart:async';

import 'package:web/web.dart' as web;

import './morph_patch.dart';
import './reactive.dart' as rx;
import './router.dart' as router;

final class _EffectState {
  _EffectState({
    required this.deps,
    required this.effect,
    this.cleanup,
    this.pending = true,
  });

  List<Object?> deps;
  rx.EffectFn effect;
  rx.Cleanup? cleanup;
  bool pending;
}

final class Ref<T> {
  Ref(this.value);
  T value;
}

final class ReducerHandle<S, A> {
  ReducerHandle._(this._component, this._boxRef);

  final Component _component;
  final Ref<_ReducerBox<S, A>?> _boxRef;

  S get state => _boxRef.value!.state;

  void dispatch(A action) {
    final box = _boxRef.value;
    if (box == null) return;
    _component.setState(() {
      box.state = box.reducer(box.state, action);
    });
  }
}

final class _Memo<T> {
  _Memo({required this.deps, required this.value});
  final List<Object?> deps;
  final T value;
}

final class _ReducerBox<S, A> {
  _ReducerBox({required this.state, required this.reducer});
  S state;
  S Function(S state, A action) reducer;
}

final class RenderScheduler {
  RenderScheduler._();

  static final RenderScheduler instance = RenderScheduler._();

  final Set<Component> _dirty = <Component>{};
  bool _scheduled = false;

  void invalidate(Component component) {
    _dirty.add(component);
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_flush);
  }

  void _flush() {
    _scheduled = false;
    if (_dirty.isEmpty) return;

    final toRender = List<Component>.from(_dirty);
    _dirty.clear();

    for (final component in toRender) {
      component._performRender();
    }
  }
}

abstract class Component {
  Component();

  late web.Element _root;
  bool _mounted = false;
  final List<void Function()> _cleanups = <void Function()>[];
  final Map<String, _EffectState> _effects = <String, _EffectState>{};
  final Map<String, Object> _refs = <String, Object>{};
  final Set<Component> _children = <Component>{};
  final Map<String, Object> _context = <String, Object>{};

  web.Element render();

  void onMount() {}

  void onAfterPatch() {}

  void onDispose() {}

  web.Element get root => _root;

  bool get isMounted => _mounted;

  T? query<T extends web.Element>(String selector) {
    final el = root.querySelector(selector);
    if (el == null) return null;
    try {
      return el as T;
    } catch (_) {
      return null;
    }
  }

  T queryOrThrow<T extends web.Element>(String selector) {
    final el = query<T>(selector);
    if (el == null) {
      throw StateError(
        'Expected element "$selector" (${T.toString()}) in ${runtimeType}.root',
      );
    }
    return el;
  }

  bool get debugEnabled => router.getQueryFlag('debug');

  void debugLog(String message) {
    if (!debugEnabled) return;
    web.console.log('[dom_ui] ${runtimeType}: $message'.toJS);
  }

  void provide<T>(String key, T value) {
    _context[key] = value as Object;
  }

  T useContext<T>(String key) {
    Component? current = this;
    while (current != null) {
      final value = current._context[key];
      if (value != null) return value as T;
      current = _findParent(current);
    }
    throw StateError('Missing context for key "$key"');
  }

  Component? _findParent(Component child) {
    // Best-effort: walk from this component down its children; parent tracking
    // is stored on the child at mount time.
    return child._parent;
  }

  Component? _parent;

  void useEffect(
    String key,
    List<Object?> deps,
    rx.EffectFn effect,
  ) {
    final existing = _effects[key];
    if (existing == null) {
      _effects[key] = _EffectState(deps: deps, effect: effect);
      return;
    }

    existing.effect = effect;
    if (_depsEqual(existing.deps, deps)) return;
    existing.deps = deps;
    existing.pending = true;
    debugLog('effect "$key" deps changed');
  }

  Ref<T> useRef<T>(String key, T initialValue) {
    final existing = _refs[key];
    if (existing is Ref<T>) return existing;
    final ref = Ref<T>(initialValue);
    _refs[key] = ref;
    return ref;
  }

  rx.Signal<T> useSignal<T>(String key, T initialValue) {
    final ref = useRef<rx.Signal<T>?>(key, null);
    ref.value ??= rx.Signal<T>(initialValue);
    return ref.value!;
  }

  rx.Computed<T> useComputed<T>(
    String key,
    T Function() compute,
  ) {
    final ref = useRef<rx.Computed<T>?>(key, null);
    final existing = ref.value;
    if (existing == null) {
      final created = rx.Computed<T>(compute);
      ref.value = created;
      addCleanup(created.dispose);
      return created;
    }
    existing.updateCompute(compute);
    return existing;
  }

  T useMemo<T>(
    String key,
    List<Object?> deps,
    T Function() compute,
  ) {
    final memo = useRef<_Memo<T>?>(key, null);
    final current = memo.value;
    if (current == null || !_depsEqual(current.deps, deps)) {
      final next = _Memo<T>(deps: deps, value: compute());
      memo.value = next;
      return next.value;
    }
    return current.value;
  }

  T useCallback<T extends Function>(
    String key,
    List<Object?> deps,
    T fn,
  ) =>
      useMemo<T>(key, deps, () => fn);

  ReducerHandle<S, A> useReducer<S, A>(
    String key,
    S initialState,
    S Function(S state, A action) reducer,
  ) {
    final boxRef = useRef<_ReducerBox<S, A>?>(key, null);
    if (boxRef.value == null) {
      boxRef.value = _ReducerBox<S, A>(state: initialState, reducer: reducer);
    } else {
      boxRef.value!.reducer = reducer;
    }
    return ReducerHandle<S, A>._(this, boxRef);
  }

  bool _depsEqual(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _runEffects() {
    if (!_mounted) return;
    for (final state in _effects.values) {
      if (!state.pending) continue;
      state.pending = false;
      debugLog('run effect');
      try {
        state.cleanup?.call();
      } catch (_) {}
      state.cleanup = null;
      try {
        state.cleanup = state.effect();
      } catch (_) {
        state.cleanup = null;
      }
    }
  }

  void addCleanup(void Function() cleanup) {
    if (!_mounted) return;
    _cleanups.add(cleanup);
  }

  StreamSubscription<T> listen<T>(
    Stream<T> stream,
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final sub = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    addCleanup(() => sub.cancel());
    return sub;
  }

  void mountInto(web.Element mount) {
    if (_mounted) return;
    _root = render();
    mount.append(_root);
    _mounted = true;
    onMount();
    debugLog('mounted');
    _runEffects();
  }

  void mountChild(Component child, web.Element mount) {
    _children.add(child);
    child._parent = this;
    child.mountInto(mount);
  }

  void unmountChild(Component child) {
    if (_children.remove(child)) {
      child.dispose();
    }
  }

  void setState(void Function() fn) {
    fn();
    if (!_mounted) return;
    RenderScheduler.instance.invalidate(this);
  }

  void update(void Function() fn) => setState(fn);

  void invalidateChild(Component child) => child.invalidate();

  void invalidate() {
    if (!_mounted) return;
    RenderScheduler.instance.invalidate(this);
  }

  void _performRender() {
    if (!_mounted) return;
    debugLog('render');
    final next = render();
    morphPatch(_root, next);
    onAfterPatch();
    _runEffects();
  }

  void dispose() {
    if (!_mounted) return;
    try {
      onDispose();
    } catch (_) {}

    for (final child in _children.toList(growable: false)) {
      try {
        child.dispose();
      } catch (_) {}
    }
    _children.clear();
    _context.clear();
    _parent = null;

    for (final state in _effects.values) {
      try {
        state.cleanup?.call();
      } catch (_) {}
    }
    _effects.clear();
    _refs.clear();
    for (final cleanup in _cleanups.reversed) {
      try {
        cleanup();
      } catch (_) {}
    }
    _cleanups.clear();
    try {
      _root.remove();
    } catch (_) {}
    _mounted = false;
  }
}
