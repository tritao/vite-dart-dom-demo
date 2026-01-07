import { autoUpdate, computePosition, flip, offset, shift, size } from "@floating-ui/dom";

function toNumber(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function toBool(value, fallback) {
  if (value === true || value === false) return value;
  return fallback;
}

function parsePlacement(placement) {
  const parts = String(placement).split("-");
  const side = parts[0] || "bottom";
  const align = parts[1] || null;
  return { side, align };
}

function oppositeSide(side) {
  switch (side) {
    case "top":
      return "bottom";
    case "bottom":
      return "top";
    case "left":
      return "right";
    case "right":
      return "left";
    default:
      return side;
  }
}

function oppositeAlign(align) {
  switch (align) {
    case "start":
      return "end";
    case "end":
      return "start";
    default:
      return align;
  }
}

function withAlign(side, align) {
  return align ? `${side}-${align}` : side;
}

function fallbackPlacementsFor(placement) {
  const { side, align } = parsePlacement(placement);
  const opposite = oppositeSide(side);
  const oppAlign = align ? oppositeAlign(align) : null;

  const perpendicular =
    side === "left" || side === "right" ? ["top", "bottom"] : ["left", "right"];

  const candidates = [
    // Flip to the opposite side first.
    withAlign(opposite, align),
    // Then try the same side but different alignment.
    align ? withAlign(side, oppAlign) : null,
    // Then opposite side, different alignment.
    align ? withAlign(opposite, oppAlign) : null,
    // Finally, try perpendicular sides.
    ...perpendicular.map((s) => withAlign(s, align)),
    ...perpendicular.map((s) => (align ? withAlign(s, oppAlign) : s)),
  ].filter(Boolean);

  const out = [];
  const seen = new Set([placement]);
  for (const c of candidates) {
    if (seen.has(c)) continue;
    seen.add(c);
    out.push(c);
  }
  return out;
}

globalThis.__solidFloatToAnchor = (anchor, floating, opts = {}) => {
  const placement = typeof opts.placement === "string" ? opts.placement : "bottom-start";
  const offsetPx = toNumber(opts.offset, 8);
  const viewportPadding = toNumber(opts.viewportPadding, 8);
  const flipEnabled = toBool(opts.flip, true);
  const updateOnAnimationFrame = toBool(opts.updateOnAnimationFrame, false);
  const sameWidth = toBool(opts.sameWidth, false);
  const fitViewport = toBool(opts.fitViewport, false);
  const fallbackPlacements =
    Array.isArray(opts.fallbackPlacements) && opts.fallbackPlacements.length > 0
      ? opts.fallbackPlacements.filter((p) => typeof p === "string")
      : fallbackPlacementsFor(placement);

  const middleware = [
    offset(offsetPx),
    ...(flipEnabled
      ? [
          flip({
            padding: viewportPadding,
            rootBoundary: "viewport",
            fallbackPlacements,
          }),
        ]
      : []),
    shift({ padding: viewportPadding, rootBoundary: "viewport" }),
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
  ];

  const update = async () => {
    if (!anchor || !floating) return;
    const { x, y } = await computePosition(anchor, floating, {
      placement,
      strategy: "fixed",
      middleware,
    });
    floating.style.position = "fixed";
    floating.style.left = `${x}px`;
    floating.style.top = `${y}px`;
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
