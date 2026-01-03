import 'dart:async';

import 'package:web/web.dart' as web;

import '../morph_patch.dart';

typedef Cleanup = void Function();

final class _EffectState {
  _EffectState({
    required this.deps,
    required this.effect,
    this.cleanup,
    this.pending = true,
  });

  List<Object?> deps;
  Cleanup? Function() effect;
  Cleanup? cleanup;
  bool pending;
}

final class Ref<T> {
  Ref(this.value);
  T value;
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

  late final web.Element _root;
  bool _mounted = false;
  final List<void Function()> _cleanups = <void Function()>[];
  final Map<String, _EffectState> _effects = <String, _EffectState>{};
  final Map<String, Object> _refs = <String, Object>{};
  final Set<Component> _children = <Component>{};

  web.Element render();

  void onMount() {}

  void onAfterPatch() {}

  void onDispose() {}

  web.Element get root => _root;

  bool get isMounted => _mounted;

  void useEffect(
    String key,
    List<Object?> deps,
    Cleanup? Function() effect,
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
  }

  Ref<T> useRef<T>(String key, T initialValue) {
    final existing = _refs[key];
    if (existing is Ref<T>) return existing;
    final ref = Ref<T>(initialValue);
    _refs[key] = ref;
    return ref;
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
    _runEffects();
  }

  void mountChild(Component child, web.Element mount) {
    _children.add(child);
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
    _mounted = false;
  }
}
