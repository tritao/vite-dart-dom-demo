import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:test/test.dart";

Future<void> pump() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group("solid runtime", () {
    test("effect tracks signal and reruns on change", () async {
      final runs = <int>[];
      late Signal<int> count;

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        count = createSignal<int>(0);
        createEffect(() {
          runs.add(count.value);
        });
      });

      expect(runs, [0]);
      count.value = 1;
      await pump();
      expect(runs, [0, 1]);

      dispose();
      count.value = 2;
      await pump();
      expect(runs, [0, 1]);
    });

    test("dynamic dependencies switch correctly", () async {
      final hits = <String>[];

      late Signal<bool> useA;
      late Signal<int> a;
      late Signal<int> b;

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        useA = createSignal<bool>(true);
        a = createSignal<int>(0);
        b = createSignal<int>(0);

        createEffect(() {
          if (useA.value) {
            hits.add("a:${a.value}");
          } else {
            hits.add("b:${b.value}");
          }
        });
      });

      expect(hits, ["a:0"]);

      a.value = 1;
      await pump();
      expect(hits.last, "a:1");

      useA.value = false;
      await pump();
      expect(hits.last, "b:0");

      a.value = 2;
      await pump();
      expect(hits.last, "b:0");

      b.value = 3;
      await pump();
      expect(hits.last, "b:3");

      dispose();
    });

    test("onCleanup runs before rerun and on dispose", () async {
      final log = <String>[];
      late Signal<int> s;
      late Dispose dispose;

      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createEffect(() {
          onCleanup(() => log.add("cleanup"));
          log.add("run:${s.value}");
        });
      });

      expect(log, ["run:0"]);

      s.value = 1;
      await pump();
      expect(log, ["run:0", "cleanup", "run:1"]);

      dispose();
      expect(log, ["run:0", "cleanup", "run:1", "cleanup"]);
    });

    test("batch coalesces multiple writes", () async {
      late Signal<int> s;
      final seen = <int>[];

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createEffect(() => seen.add(s.value));
      });

      expect(seen, [0]);

      batch(() {
        s.value = 1;
        s.value = 2;
        s.value = 3;
      });

      await pump();
      expect(seen, [0, 3]);

      dispose();
    });

    test("memo caches and only recomputes when deps change", () async {
      late Signal<int> s;
      late Memo<int> m;
      var computes = 0;

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(1);
        m = createMemo(() {
          computes++;
          return s.value * 2;
        });
      });

      // Lazy: memo doesn't compute until first read.
      expect(computes, 0);
      expect(m.value, 2);
      expect(m.value, 2);
      expect(computes, 1);

      s.value = 2;
      await pump();
      expect(m.value, 4);
      expect(computes, 2);

      dispose();
    });

    test("untrack prevents subscription", () async {
      late Signal<int> s;
      var runs = 0;

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createEffect(() {
          runs++;
          untrack(() => s.value);
        });
      });

      expect(runs, 1);
      s.value = 1;
      await pump();
      expect(runs, 1);

      dispose();
    });

    test("context provides nearest value", () async {
      final ctx = createContext<String>("default");
      final values = <String>[];

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        values.add(useContext(ctx));
        provideContext(ctx, "outer", () {
          values.add(useContext(ctx));
          provideContext(ctx, "inner", () {
            values.add(useContext(ctx));
          });
          values.add(useContext(ctx));
        });
        values.add(useContext(ctx));
      });

      expect(values, ["default", "outer", "inner", "outer", "default"]);
      dispose();
    });

    test("effects observe memo changes", () async {
      late Signal<int> s;
      late Memo<int> m;
      final seen = <int>[];

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(1);
        m = createMemo(() => s.value * 10);
        createEffect(() => seen.add(m.value));
      });

      expect(seen, [10]);
      s.value = 2;
      await pump();
      expect(seen, [10, 20]);

      dispose();
    });

    test("signal equals: prevents notifications when equal", () async {
      late Signal<List<int>> s;
      final runs = <int>[];
      late Dispose dispose;

      createRoot<void>((d) {
        dispose = d;
        s = createSignal<List<int>>(
          <int>[1],
          equals: (prev, next) => prev.length == next.length,
        );
        createEffect(() => runs.add(s.value.length));
      });

      expect(runs, [1]);

      // New list, same length => treated equal => no notify.
      s.value = <int>[9];
      await pump();
      flushSync();
      expect(runs, [1]);

      // Different length => notify.
      s.value = <int>[1, 2];
      await pump();
      flushSync();
      expect(runs, [1, 2]);

      dispose();
    });

    test("render effects run before regular effects on updates", () async {
      late Signal<int> s;
      late Dispose dispose;
      final order = <String>[];

      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createRenderEffect(() => order.add("render:${s.value}"));
        createEffect(() => order.add("effect:${s.value}"));
      });

      // Initial runs occur in creation order.
      expect(order, ["render:0", "effect:0"]);

      order.clear();
      s.value = 1;
      await pump();
      flushSync();

      // On updates, render effects flush before effects.
      expect(order, ["render:1", "effect:1"]);

      dispose();
    });

    test("render effects flush before effects even in batch", () async {
      late Signal<int> s;
      late Dispose dispose;
      final order = <String>[];

      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createRenderEffect(() => order.add("render:${s.value}"));
        createEffect(() => order.add("effect:${s.value}"));
      });

      order.clear();
      batch(() {
        s.value = 1;
        s.value = 2;
      });
      await pump();

      // Only final value should be observed, and render should precede effect.
      expect(order, ["render:2", "effect:2"]);

      dispose();
    });

    test("runWithOwner enables child roots in async callbacks", () async {
      final log = <String>[];
      late Dispose disposeRoot;
      Owner? owner;
      Dispose? disposeChild;

      createRoot<void>((d) {
        disposeRoot = d;
        owner = getOwner();
      });

      scheduleMicrotask(() {
        runWithOwner(owner, () {
          disposeChild = createChildRoot<Dispose>((dispose) {
            onCleanup(() => log.add("child-cleanup"));
            return dispose;
          });
        });
      });

      await pump();
      expect(disposeChild, isNotNull);

      disposeChild?.call();
      expect(log, ["child-cleanup"]);

      disposeRoot();
    });

    test("resource: starts loading, resolves value, notifies dependents",
        () async {
      final states = <String>[];
      late Resource<int> r;
      late Dispose dispose;

      final completer = Completer<int>();
      createRoot<void>((d) {
        dispose = d;
        r = createResource(() => completer.future);
        createEffect(() {
          states.add("loading=${r.loading} value=${r.value}");
        });
      });

      expect(states, ["loading=true value=null"]);

      completer.complete(123);
      await pump();
      flushSync();
      expect(states.last, "loading=false value=123");

      dispose();
    });

    test("resource: cancellation ignores stale results", () async {
      late Signal<int> id;
      late Resource<String> r;
      late Dispose dispose;

      final c1 = Completer<String>();
      final c2 = Completer<String>();

      createRoot<void>((d) {
        dispose = d;
        id = createSignal<int>(1);
        r = createResourceWithSource<int, String>(
          () => id.value,
          (v) => v == 1 ? c1.future : c2.future,
        );
      });

      expect(r.loading, true);

      id.value = 2;
      await pump();
      flushSync();

      c2.complete("two");
      await pump();
      flushSync();
      expect(r.value, "two");
      expect(r.loading, false);

      c1.complete("one");
      await pump();
      flushSync();
      expect(r.value, "two");
      expect(r.loading, false);

      dispose();
    });

    test("resource: dispose prevents late resolution", () async {
      late Resource<int> r;
      late Dispose dispose;
      final completer = Completer<int>();

      createRoot<void>((d) {
        dispose = d;
        r = createResource(() => completer.future);
      });

      dispose();
      completer.complete(9);
      await pump();
      flushSync();
      expect(r.value, isNull);
    });

    test("resource: error is captured and loading stops", () async {
      late Resource<int> r;
      late Dispose dispose;
      final completer = Completer<int>();

      createRoot<void>((d) {
        dispose = d;
        r = createResource(() => completer.future);
      });

      completer.completeError(StateError("boom"));
      await pump();
      flushSync();
      expect(r.loading, false);
      expect(r.error, isA<StateError>());

      dispose();
    });

    test("selector: only affected keys rerun", () async {
      late Signal<int> selected;
      late Selector<int> sel;
      late Dispose dispose;

      var aRuns = 0;
      var bRuns = 0;
      var cRuns = 0;
      final aStates = <bool>[];
      final bStates = <bool>[];
      final cStates = <bool>[];

      createRoot<void>((d) {
        dispose = d;
        selected = createSignal<int>(1);
        sel = createSelector<int>(() => selected.value);

        createEffect(() {
          aRuns++;
          aStates.add(sel.isSelected(1));
        });
        createEffect(() {
          bRuns++;
          bStates.add(sel.isSelected(2));
        });
        createEffect(() {
          cRuns++;
          cStates.add(sel.isSelected(3));
        });
      });

      expect([aRuns, bRuns, cRuns], [1, 1, 1]);
      expect(aStates.last, true);
      expect(bStates.last, false);
      expect(cStates.last, false);

      selected.value = 2;
      await pump();
      flushSync();

      // Only keys 1 and 2 flip. Key 3 stays false and should not re-run.
      expect([aRuns, bRuns, cRuns], [2, 2, 1]);
      expect(aStates.last, false);
      expect(bStates.last, true);
      expect(cStates.last, false);

      selected.value = 3;
      await pump();
      flushSync();
      expect([aRuns, bRuns, cRuns], [2, 3, 2]);
      expect(bStates.last, false);
      expect(cStates.last, true);

      dispose();
    });

    test("selector: effect can switch which key it tracks", () async {
      late Signal<int> selected;
      late Signal<int> key;
      late Selector<int> sel;
      late Dispose dispose;

      final seen = <bool>[];
      createRoot<void>((d) {
        dispose = d;
        selected = createSignal<int>(1);
        key = createSignal<int>(1);
        sel = createSelector<int>(() => selected.value);
        createEffect(() => seen.add(sel.isSelected(key.value)));
      });

      expect(seen, [true]);

      key.value = 2;
      await pump();
      flushSync();
      expect(seen.last, false);

      selected.value = 2;
      await pump();
      flushSync();
      expect(seen.last, true);

      selected.value = 3;
      await pump();
      flushSync();
      expect(seen.last, false);

      dispose();
    });

    test("child root: dispose stops updates without affecting parent",
        () async {
      late Signal<int> s;
      late Dispose disposeParent;
      late Dispose disposeChild;

      final parentRuns = <int>[];
      final childRuns = <int>[];

      createRoot<void>((d) {
        disposeParent = d;
        s = createSignal<int>(0);

        createEffect(() => parentRuns.add(s.value));

        createChildRoot<void>((cd) {
          disposeChild = cd;
          createEffect(() => childRuns.add(s.value));
        });
      });

      expect(parentRuns, [0]);
      expect(childRuns, [0]);

      s.value = 1;
      await pump();
      flushSync();
      expect(parentRuns, [0, 1]);
      expect(childRuns, [0, 1]);

      disposeChild();
      s.value = 2;
      await pump();
      flushSync();
      expect(parentRuns, [0, 1, 2]);
      expect(childRuns, [0, 1]);

      disposeParent();
    });

    test("child root: disposing parent disposes children", () async {
      late Signal<int> s;
      late Dispose disposeParent;
      late Dispose disposeChild;

      final childRuns = <int>[];
      final childCleanups = <String>[];

      createRoot<void>((d) {
        disposeParent = d;
        s = createSignal<int>(0);
        createChildRoot<void>((cd) {
          disposeChild = cd;
          createEffect(() {
            onCleanup(() => childCleanups.add("cleanup"));
            childRuns.add(s.value);
          });
        });
      });

      expect(childRuns, [0]);

      disposeParent();

      // Child should already be disposed by the parent.
      disposeChild();
      s.value = 1;
      await pump();
      flushSync();
      expect(childRuns, [0]);
      expect(childCleanups, ["cleanup"]);
    });

    test("child root: cleanup runs on child dispose", () async {
      late Dispose disposeParent;
      late Dispose disposeChild;
      final log = <String>[];

      createRoot<void>((d) {
        disposeParent = d;
        createChildRoot<void>((cd) {
          disposeChild = cd;
          createEffect(() {
            onCleanup(() => log.add("cleanup"));
            log.add("run");
          });
        });
      });

      expect(log, ["run"]);
      disposeChild();
      expect(log, ["run", "cleanup"]);
      disposeParent();
    });

    test(
        "error handling: global handler captures effect errors and scheduler continues",
        () async {
      final errors = <String>[];
      setGlobalErrorHandler((error, _) => errors.add(error.toString()));

      late Signal<int> s;
      final okRuns = <int>[];
      late Dispose dispose;

      createRoot<void>((d) {
        dispose = d;
        s = createSignal<int>(0);
        createEffect(() {
          if (s.value == 1) throw StateError("boom");
        });
        createEffect(() => okRuns.add(s.value));
      });

      expect(okRuns, [0]);

      s.value = 1;
      await pump();
      flushSync();
      expect(errors.any((e) => e.contains("boom")), true);
      // Second effect should still run even if the first throws.
      expect(okRuns.last, 1);

      s.value = 2;
      await pump();
      flushSync();
      expect(okRuns.last, 2);

      dispose();
      clearGlobalErrorHandler();
    });

    test("error handling: owner handler overrides global handler", () async {
      final global = <String>[];
      final local = <String>[];
      setGlobalErrorHandler((error, _) => global.add("g:$error"));

      late Dispose dispose;
      createRoot<void>((d) {
        dispose = d;
        // Set an owner-scoped handler.
        setErrorHandler((error, _) => local.add("l:$error"));
        final s = createSignal<int>(0);
        createEffect(() {
          if (s.value == 1) throw StateError("local-boom");
        });
        s.value = 1;
      });

      await pump();
      flushSync();
      expect(local.any((e) => e.contains("local-boom")), true);
      expect(global.any((e) => e.contains("local-boom")), false);

      dispose();
      clearGlobalErrorHandler();
    });
  });
}
