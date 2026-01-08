#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _resize_by_width(img: Image.Image, *, width: int) -> Image.Image:
    w, h = img.size
    if w == width:
        return img
    height = max(1, round(h * (width / w)))
    return img.resize((width, height), Image.Resampling.LANCZOS)


def _center_square_crop(img: Image.Image, *, side: int) -> Image.Image:
    w, h = img.size
    side = min(side, w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Solidus brand assets for public/assets.")
    parser.add_argument(
        "--logo",
        type=Path,
        default=Path("/home/joao/Downloads/solidus_logo.png"),
        help="Path to solidus_logo.png (default: /home/joao/Downloads/solidus_logo.png)",
    )
    parser.add_argument(
        "--mark",
        type=Path,
        default=Path("/home/joao/Downloads/solidus_small_logo.png"),
        help="Path to solidus_small_logo.png (default: /home/joao/Downloads/solidus_small_logo.png)",
    )
    parser.add_argument("--outdir", type=Path, default=Path("public/assets"))
    parser.add_argument("--logo-width", type=int, default=720)
    parser.add_argument("--mark-size", type=int, default=64)
    parser.add_argument(
        "--mark-crop-ratio",
        type=float,
        default=0.72,
        help="Crop ratio relative to min(image side) for the nav mark (default: 0.72).",
    )
    args = parser.parse_args()

    outdir: Path = args.outdir
    outdir.mkdir(parents=True, exist_ok=True)

    logo_src: Path = args.logo
    mark_src: Path = args.mark

    if not logo_src.exists():
        raise SystemExit(f"Missing logo source: {logo_src}")
    if not mark_src.exists():
        raise SystemExit(f"Missing mark source: {mark_src}")

    # Regular logo: keep full canvas, just downscale for web usage.
    with Image.open(logo_src) as img:
        img = img.convert("RGBA")
        logo = _resize_by_width(img, width=args.logo_width)
        logo.save(outdir / "solidus-logo.png", format="PNG", optimize=True)

    # Navbar mark: crop around the emblem and downscale to a small square.
    with Image.open(mark_src) as img:
        img = img.convert("RGBA")
        w, h = img.size
        crop_side = max(1, round(min(w, h) * float(args.mark_crop_ratio)))
        cropped = _center_square_crop(img, side=crop_side)
        mark = cropped.resize((args.mark_size, args.mark_size), Image.Resampling.LANCZOS)
        mark.save(outdir / "solidus-mark.png", format="PNG", optimize=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
