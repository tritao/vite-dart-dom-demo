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

### `BrowserRouter`

Tracks the current location, computes matches/params, and provides navigation helpers.

Use it once per app (usually at the root).

### `RouteDef` / `RouteMatch`

Defines route patterns and the match results (including merged `params`).

Use `RouteDef(children: ...)` for nesting.

### `RouterProvider(router: ..., children: ...)`

Provides the router to the subtree.

Use it to wrap the part of your app that needs routing hooks/components.

### `Routes(fallback: ...)`

Renders the best match chain and wires up nested routes via `Outlet()`.

Use it as the “router outlet” of your app.

### `Outlet()`

Placeholder for nested route children.

Use it inside a parent route view that wants to render its child route.

### `Link(to: ... | toFn: ...)`

Client-side navigation without full page reload.

Use it instead of raw `<a href>` for internal links.

### Hooks: `useLocation`, `useMatches`, `useParams`, `useSearchParams`, `useNavigate`

Small helpers for reading router state and navigating.

Use them inside code that runs under `RouterProvider`.

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

## Matches (`useMatches`)

`useMatches()` returns the current match chain (root → leaf). This is useful for:

- building breadcrumbs
- per-route layouts (based on matched path)
- deciding which “shell” to show for a section of the app

```dart
final matches = useMatches();

createEffect(() {
  final paths = [for (final m in matches.value) m.matchedPath].join(" → ");
  // e.g. log, render breadcrumbs, etc.
});
```

## Router helpers (`href` / `resolve`)

`BrowserRouter.href(to)` computes a browser URL for a destination string. `resolve(to)` returns the internal `Uri` relative to the current location.

Use this when you need URLs outside of `Link` (e.g. setting `location.href`, building a copy-link button).

```dart
final router = useRouter();

final copy = web.HTMLButtonElement()
  ..type = "button"
  ..textContent = "Copy link";
on(copy, "click", (_) {
  final url = router.href("/users/123?tab=billing");
  // copy to clipboard, etc.
});
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

## Hosting note (history routing)

For path routing on static hosts, you typically need a “SPA fallback” (rewrite all paths to your `index.html`).
Vite dev/preview handles this automatically; GitHub Pages usually needs extra configuration (e.g. a `404.html` redirect).
