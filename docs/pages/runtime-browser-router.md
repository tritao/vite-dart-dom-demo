---
title: Browser router (paths + params)
slug: runtime-browser-router
group: Runtime
order: 70
description: A small path-based router with params, nested routes, Links, and navigation.
status: beta
tags: [runtime, router]
---

For larger apps, Solidus provides a **path-based** browser router built on the Solidus reactive runtime.

If you only need querystring helpers (like `?docs=...`), see: [Routing (URL query)](?docs=runtime-router).

## Pieces

- `BrowserRouter`: tracks location and updates on `popstate` / `hashchange`
- `Routes`: renders the best match (supports nested routes)
- `Link`: client-side navigation without full page reload
- Hooks: `useLocation`, `useNavigate`, `useParams`, `useMatches`
- `Outlet()`: placeholder for nested route children

All are exported from `package:solidus/solidus_router.dart`.

## Matching rules (important)

- **First match wins**: routes are tried in the order you provide them; put more specific routes first.
- **Nested paths are relative**: child routes like `profile` match under the parent path.
- **Absolute child paths**: a child path that starts with `/` is matched from the root.
- **Index routes**: `RouteDef(index: true, ...)` matches only when all segments are consumed.
- **Pathless layout routes**: `RouteDef(path: null, ...)` wraps children without consuming segments.
- **Splat**: `*` captures remaining segments into `params["splat"]`.

## Router setup

```dart
import "package:solidus/solidus.dart";
import "package:solidus/solidus_dom.dart";
import "package:solidus/solidus_router.dart";
import "package:web/web.dart" as web;

Dispose mountApp(web.Element mount) {
  return render(mount, () {
    final router = BrowserRouter(
      basePath: "", // set to "/my-subpath" if hosting under a subpath
      routes: [
        RouteDef(
          path: "/",
          view: (m) {
            final root = web.HTMLDivElement()..textContent = "Home";
            root.appendChild(Link(to: "/users/123", child: "Go to user 123"));
            return root;
          },
        ),
        RouteDef(
          path: "/users/:id",
          view: (m) => web.HTMLDivElement()..textContent = "User id=${m.params["id"]}",
        ),
      ],
    );

    onCleanup(router.dispose);

    return RouterProvider(
      router: router,
      children: () => Routes(
        fallback: () => (web.HTMLDivElement()..textContent = "Not found"),
      ),
    );
  });
}
```

## Nested routes + `Outlet()`

Nested routes are defined via `children`. Parent routes can render the child route via `Outlet()`.

```dart
final router = BrowserRouter(routes: [
  RouteDef(
    path: "/settings",
    view: (m) {
      final root = web.HTMLDivElement()..textContent = "Settings";
      root.appendChild(insert(root, () => Outlet()));
      return root;
    },
    children: [
      RouteDef(path: "profile", view: (_) => web.HTMLDivElement()..textContent = "Profile"),
      RouteDef(path: "billing", view: (_) => web.HTMLDivElement()..textContent = "Billing"),
      RouteDef(index: true, view: (_) => web.HTMLDivElement()..textContent = "Pick a tab"),
    ],
  ),
]);
```

## Layout route (pathless parent)

Use `path: null` when you want a “layout” wrapper that always renders, regardless of the child path.

```dart
final router = BrowserRouter(routes: [
  RouteDef(
    path: null, // layout
    view: (_) {
      final root = web.HTMLDivElement();
      root.appendChild(web.HTMLDivElement()..textContent = "App chrome");
      root.appendChild(insert(root, () => Outlet()));
      return root;
    },
    children: [
      RouteDef(path: "/", view: (_) => web.HTMLDivElement()..textContent = "Home"),
      RouteDef(path: "/users/:id", view: (_) => web.HTMLDivElement()..textContent = "User"),
      RouteDef(path: "*", view: (_) => web.HTMLDivElement()..textContent = "Not found"),
    ],
  ),
]);
```

## Params + navigation

```dart
final params = useParams();
final nav = useNavigate();

final userId = params["id"]; // reactive read

final btn = web.HTMLButtonElement()
  ..type = "button"
  ..textContent = "Go home";
on(btn, "click", (_) => nav("/", replace: true));
```

## Search params (querystring)

`useSearchParams()` gives you a small helper for `?k=v` on top of the current path.

```dart
final sp = useSearchParams();

final view = sp.get("view") ?? "grid";

final btn = web.HTMLButtonElement()
  ..type = "button"
  ..textContent = "Toggle view";
on(btn, "click", (_) {
  sp.set("view", view == "grid" ? "list" : "grid", replace: false);
});
```

## Active links (basic)

Solidus doesn’t impose an “active link” API. A simple pattern:

```dart
final loc = useLocation();
final a = Link(toFn: () => "/settings/profile", child: "Profile");

createRenderEffect(() {
  final active = loc.value.path == "/settings/profile";
  a.className = active ? "active" : "";
});
```

## Is this enough for serious apps?

Yes for many SPAs, as long as you’re okay with a **small, explicit** router:

- You get nested routes, params, query helpers, and `Link`/`navigate`.
- You don’t get “full framework router” features like loaders/actions, route ranking, scroll restoration, transitions, prefetching, or error boundaries.

If you need those, a reasonable next step is a higher-level layer on top of this router (route tree + loaders + pending/error UI) while keeping `BrowserRouter` as the primitive.

## “What people expect” (a realistic next design)

If Solidus grows a higher-level router, the usual expectations are:

- **Route ranking** (so `/users/:id` doesn’t depend on manual ordering)
- **Loaders + pending UI** (data loading per route, with `pendingView`)
- **Error UI** (route-level error boundaries, `errorView`)
- **Redirects** (`redirect(to)` from loaders or guards)
- **Scroll restoration** (optional but expected)
- **Prefetching** (`Link(prefetch: ...)` or `router.preload(...)`)

A simple (still-Dart/DOM-first) shape could look like:

```dart
final routes = [
  RouteDef(
    path: "/users/:id",
    // loader: (match) async => await fetchUser(match.params["id"]!),
    view: (m) => UserPage(id: m.params["id"]!),
    // pendingView: (_) => Spinner(),
    // errorView: (e) => ErrorPanel(e),
  ),
];
```

## Hosting note (history routing)

For path routing on static hosts, you typically need a “SPA fallback” (rewrite all paths to your `index.html`).
Vite dev/preview handles this automatically; GitHub Pages usually needs extra configuration (e.g. a `404.html` redirect).
