import "package:solidus/solidus_router/match.dart";
import "package:test/test.dart";

void main() {
  group("solidus_router matchRoutes", () {
    test("matches root route", () {
      final routes = <RouteDef>[
        RouteDef(path: "/", view: (_) => null),
      ];
      final matches = matchRoutes(routes, "/");
      expect(matches.length, 1);
      expect(matches.single.matchedPath, "/");
      expect(matches.single.params, const <String, String>{});
    });

    test("matches params", () {
      final routes = <RouteDef>[
        RouteDef(path: "/users/:id", view: (_) => null),
      ];
      final matches = matchRoutes(routes, "/users/123");
      expect(matches.length, 1);
      expect(matches.single.matchedPath, "/users/123");
      expect(matches.single.params, const <String, String>{"id": "123"});
    });

    test("matches nested routes with Outlet semantics", () {
      final routes = <RouteDef>[
        RouteDef(
          path: "/settings",
          view: (_) => null,
          children: <RouteDef>[
            RouteDef(path: "profile", view: (_) => null),
          ],
        ),
      ];
      final matches = matchRoutes(routes, "/settings/profile");
      expect(matches.length, 2);
      expect(matches[0].matchedPath, "/settings");
      expect(matches[1].matchedPath, "/settings/profile");
    });

    test("matches index route only at parent boundary", () {
      final routes = <RouteDef>[
        RouteDef(
          path: "/settings",
          view: (_) => null,
          children: <RouteDef>[
            RouteDef(index: true, view: (_) => null),
            RouteDef(path: "profile", view: (_) => null),
          ],
        ),
      ];

      final onParent = matchRoutes(routes, "/settings");
      expect(onParent.length, 2);
      expect(onParent[1].route.index, true);

      final onChild = matchRoutes(routes, "/settings/profile");
      expect(onChild.length, 2);
      expect(onChild[1].route.index, false);
    });

    test("supports pathless layout routes", () {
      final routes = <RouteDef>[
        RouteDef(
          path: null,
          view: (_) => null,
          children: <RouteDef>[
            RouteDef(path: "/users/:id", view: (_) => null),
          ],
        ),
      ];
      final matches = matchRoutes(routes, "/users/1");
      expect(matches.length, 2);
      expect(matches[0].matchedPath, "/");
      expect(matches[1].matchedPath, "/users/1");
      expect(matches.last.params, const <String, String>{"id": "1"});
    });

    test("supports splat wildcard", () {
      final routes = <RouteDef>[
        RouteDef(path: "/files/*", view: (_) => null),
      ];
      final matches = matchRoutes(routes, "/files/a/b/c");
      expect(matches.length, 1);
      expect(matches.single.params, const <String, String>{"splat": "a/b/c"});
      expect(matches.single.matchedPath, "/files/a/b/c");
    });

    test("returns empty when no routes match", () {
      final routes = <RouteDef>[
        RouteDef(path: "/a", view: (_) => null),
        RouteDef(path: "/b", view: (_) => null),
      ];
      expect(matchRoutes(routes, "/c"), isEmpty);
    });

    test("supports root catch-all", () {
      final routes = <RouteDef>[
        RouteDef(path: "*", view: (_) => null),
      ];
      final matches = matchRoutes(routes, "/x/y");
      expect(matches.length, 1);
      expect(matches.single.params, const <String, String>{"splat": "x/y"});
      expect(matches.single.matchedPath, "/x/y");
    });
  });
}
