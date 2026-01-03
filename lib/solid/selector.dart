part of "solid.dart";

/// A selector is an efficient equality-based subscription primitive.
///
/// Consumers call `isSelected(key)` inside effects/memos. Only consumers whose
/// key's selection state changes are re-run when the underlying source changes.
final class Selector<K> {
  Selector._(this._owner, this._source, this._equals) {
    _computation = Computation._(_update, _owner, isMemo: true, autoRun: false);
  }

  final Owner _owner;
  final Object? Function() _source;
  final bool Function(Object? a, Object? b) _equals;

  late final Computation _computation;
  Object? _current;
  bool _hasCurrent = false;

  final Map<K, _SelectorDep<K>> _deps = <K, _SelectorDep<K>>{};

  bool isSelected(K key) {
    final dep = _deps.putIfAbsent(key, () => _SelectorDep<K>(this, key));
    final computation = _currentComputation;
    if (computation != null) computation._track(dep);
    final current = _read();
    return _equals(current, key);
  }

  Object? _read() {
    if (!_hasCurrent) {
      _computation._run();
    }
    return _current;
  }

  void _update() {
    Object? next;
    try {
      next = _source();
    } catch (e, st) {
      _reportError(_owner, e, st);
      return;
    }
    if (!_hasCurrent) {
      _current = next;
      _hasCurrent = true;
      return;
    }
    final prev = _current;
    if (_equals(prev, next)) return;
    _current = next;

    // Only keys whose (prev==key) XOR (next==key) changed should notify.
    for (final dep in _deps.values.toList(growable: false)) {
      final was = _equals(prev, dep.key);
      final now = _equals(next, dep.key);
      if (was != now) dep._notify();
    }
  }
}

final class _SelectorDep<K> implements Dependency {
  _SelectorDep(this.selector, this.key);

  final Selector<K> selector;
  final K key;
  final Set<Computation> _subscribers = <Computation>{};

  void _notify() {
    if (_subscribers.isEmpty) return;
    for (final sub in _subscribers.toList(growable: false)) {
      sub._markStale();
    }
  }

  @override
  void _subscribe(Computation computation) => _subscribers.add(computation);

  @override
  void _unsubscribe(Computation computation) =>
      _subscribers.remove(computation);
}

Selector<K> createSelector<K>(
  Object? Function() source, {
  bool Function(Object? a, Object? b)? equals,
}) {
  final owner = _currentOwner;
  if (owner == null) {
    throw StateError("createSelector() called with no active owner");
  }
  return Selector<K>._(owner, source, equals ?? (a, b) => a == b);
}
