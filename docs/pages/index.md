---
title: Introduction
slug: index
group: Docs
order: 0
description: What this project is, and how the docs and labs are structured.
status: beta
tags: [docs]
---

<p class="docBrand">
  <img class="docLogo" src="assets/solidus-logo.png" alt="Solidus logo" />
</p>

This project aims to make it practical to build **robust web applications in Dart** with a UI layer that feels modern, reactive, and accessible.

It combines:

- A **Solid-like reactive runtime** (signals, effects, resources, ownership).
- A growing set of **accessible DOM primitives** inspired by Kobalte/Radix-style behavior (overlays, menus, selection, positioning).
- A focus on **correct semantics and keyboard behavior**, backed by automated scenarios.

## Who this is for

- Teams who want to ship production-grade UI on the web, but prefer **Dart** as the primary language.
- People who like the **Solid mental model** (fine-grained reactivity) and want it in Dart.
- Anyone who cares about **accessibility parity** (focus management, dismiss behavior, ARIA, keyboard nav) without reinventing it for every widget.

## What the runtime gives you

The runtime provides the basics you need to build UI without a heavyweight framework:

- **Signals and derivations**: update state and automatically re-render only the pieces that depend on it.
- **Effects**: react to state changes, with render effects intended for DOM writes.
- **Ownership & cleanup**: structured lifetimes for timers/listeners/subtrees so teardown is reliable.
- **Resources**: async values with `loading` / `error` state integrated into reactivity.
- **Context**: scoped values for configuration and shared services.

## What the UI layer gives you

The primitives are designed to be composed into “real” components while keeping behaviors correct:

- **Overlay foundations**: portals, presence/animations, dismissable layers, scroll lock, aria-hiding.
- **Focus management**: focus scopes and trapping for modals/menus.
- **Positioning**: popper-style anchored floating UIs (with a Floating UI bridge when available).
- **Selection core**: keyboard navigation + typeahead + disabled skipping for list-like UIs.

These foundations power components like Dialog, Popover, Tooltip, DropdownMenu, Select, Combobox, Tabs, Accordion, Switch, and more.

## How to use these docs

Use the docs as the “happy path” reference:

- Start with the **Runtime** pages if you’re new to the reactive model.
- Use **Foundations** to understand the shared behaviors that underpin multiple components.
- Use the component pages when you want a minimal example and the API surface.

When you need to validate edge cases (nested overlays, flip/slide positioning, click-through prevention), jump to the labs and run the automated scenarios.

## Next steps

- Runtime: [Reactivity](?docs=runtime-reactivity), [Router](?docs=runtime-browser-router)
- Foundations: [DOM DSL](?docs=dom-dsl), [Overlay](?docs=overlay), [FocusScope](?docs=focus-scope), [Popper / Positioning](?docs=popper), [Selection core](?docs=selection-core)
- Forms: [Forms](?docs=forms), [FormField](?docs=form-field), [Input](?docs=input), [Combobox](?docs=combobox)
- UI: [Button](?docs=button), [Tabs](?docs=tabs), [Accordion](?docs=accordion)
