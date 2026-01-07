import { arrow, autoUpdate, computePosition, flip, hide, offset, shift, size } from "@floating-ui/dom";

function toNumber(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function toBool(value, fallback) {
  if (value === true || value === false) return value;
  return fallback;
}

globalThis.__solidFloatToAnchor = (anchor, floating, opts = {}) => {
  const placement = typeof opts.placement === "string" ? opts.placement : "bottom-start";
  const gutterPx = toNumber(opts.offset, 8);
  const shiftPx = toNumber(opts.shift, 0);
  const viewportPadding = toNumber(opts.viewportPadding, 8);
  const flipEnabled = toBool(opts.flip, true);
  const slide = toBool(opts.slide, true);
  const overlap = toBool(opts.overlap, false);
  const updateOnAnimationFrame = toBool(opts.updateOnAnimationFrame, false);
  const sameWidth = toBool(opts.sameWidth, false);
  const fitViewport = toBool(opts.fitViewport, false);
  const hideWhenDetached = toBool(opts.hideWhenDetached, false);
  const detachedPadding = toNumber(opts.detachedPadding, 0);
  const arrowEl = opts.arrow && typeof opts.arrow === "object" ? opts.arrow : null;
  const arrowPadding = toNumber(opts.arrowPadding, 4);
  const fallbackPlacements =
    Array.isArray(opts.fallbackPlacements) && opts.fallbackPlacements.length > 0
      ? opts.fallbackPlacements.filter((p) => typeof p === "string")
      : undefined;

  const middleware = [
    offset(({ placement }) => {
      const hasAlignment = !!String(placement).split("-")[1];
      return {
        mainAxis: gutterPx,
        // If there's no placement alignment (*-start or *-end), fall back to
        // crossAxis as it also works for center-aligned placements.
        crossAxis: !hasAlignment ? shiftPx : undefined,
        alignmentAxis: shiftPx,
      };
    }),
    ...(flipEnabled
      ? (() => {
          const flipOpts = {
            padding: viewportPadding,
          };
          if (fallbackPlacements) flipOpts.fallbackPlacements = fallbackPlacements;
          return [flip(flipOpts)];
        })()
      : []),
    ...(slide || overlap
      ? [
          (() => {
            const shiftOpts = {
              padding: viewportPadding,
              // Floating UI only applies crossAxis shifting meaningfully when it
              // can also shift the main axis; keep overlap-only meaningful by
              // enabling mainAxis shift when overlap is true.
              //
              // Kobalte sets `mainAxis: slide, crossAxis: overlap`, but we
              // intentionally diverge here so the `slide=false, overlap=true`
              // combination still clamps within the viewport.
              mainAxis: slide || overlap,
              crossAxis: overlap,
            };
            return shift(shiftOpts);
          })(),
        ]
      : []),
    size({
      padding: viewportPadding,
      apply({ availableWidth, availableHeight, rects }) {
        const referenceWidth = Math.round(rects.reference.width);
        const aw = Math.floor(availableWidth);
        const ah = Math.floor(availableHeight);

        floating.style.setProperty("--solid-popper-anchor-width", `${referenceWidth}px`);
        floating.style.setProperty("--solid-popper-content-available-width", `${aw}px`);
        floating.style.setProperty("--solid-popper-content-available-height", `${ah}px`);

        if (sameWidth) {
          if (!floating.style.boxSizing) floating.style.boxSizing = "border-box";
          floating.style.width = `${referenceWidth}px`;
        }

        if (fitViewport) {
          if (!floating.style.boxSizing) floating.style.boxSizing = "border-box";
          floating.style.maxWidth = `${aw}px`;
          floating.style.maxHeight = `${ah}px`;
        }
      },
    }),
    ...(hideWhenDetached ? [hide({ padding: detachedPadding })] : []),
    ...(arrowEl ? [arrow({ element: arrowEl, padding: arrowPadding })] : []),
  ];

  // Avoid a 1-frame flash in the wrong place: Dart marks newly-mounted poppers
  // as pending until the first computePosition completes.
  const isPending = () =>
    floating?.getAttribute?.("data-solid-popper-pending") === "1";
  const clearPending = () => {
    try {
      if (!isPending()) return;
      floating.removeAttribute("data-solid-popper-pending");
    } catch {}
  };

  const update = async () => {
    if (!anchor || !floating) return;
    if (!anchor.isConnected || !floating.isConnected) return;
    const pos = await computePosition(anchor, floating, {
      placement,
      strategy: "fixed",
      middleware,
    });
    const x = Math.round(pos.x);
    const y = Math.round(pos.y);

    floating.style.position = "fixed";
    floating.style.top = "0";
    floating.style.left = "0";
    floating.style.transform = `translate3d(${x}px, ${y}px, 0)`;
    try {
      floating.setAttribute("data-solid-placement", pos.placement);
      floating.style.setProperty("--solid-popper-current-placement", pos.placement);
    } catch {}

    if (hideWhenDetached) {
      const hidden = pos.middlewareData?.hide?.referenceHidden;
      floating.style.visibility = hidden ? "hidden" : "visible";
    }
    clearPending();

    if (arrowEl && pos.middlewareData?.arrow) {
      const { x: ax, y: ay } = pos.middlewareData.arrow;
      const base = String(pos.placement).split("-")[0];
      // reset
      arrowEl.style.left = "";
      arrowEl.style.top = "";
      arrowEl.style.right = "";
      arrowEl.style.bottom = "";
      if (ax != null) arrowEl.style.left = `${ax}px`;
      if (ay != null) arrowEl.style.top = `${ay}px`;
      arrowEl.style[base] = "100%";
    }
  };

  const cleanup = autoUpdate(anchor, floating, update, {
    animationFrame: updateOnAnimationFrame,
  });

  // initial compute
  void update();

  return {
    dispose() {
      cleanup();
    },
  };
};
