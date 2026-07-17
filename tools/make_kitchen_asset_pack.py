#!/usr/bin/env python3
"""Create transparent Kitchen Diary PNG masters and lightweight GIF loops.

This is a fallback pack generator for cases where the Flux 2 app is not
reachable. It converts the existing kitchen image library into transparent
PNG exports and animated GIF loops with consistent, lightweight motion.

Output layout:
  generated/kitchen_asset_pack_v1/png/<relative source path>.png
  generated/kitchen_asset_pack_v1/gif/<relative category>/<stem>.gif
  generated/kitchen_asset_pack_v1/index.json
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import tempfile
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import numpy as np
from PIL import Image, ImageFilter


DEFAULT_GIF_CATEGORIES = {"actions", "blocks", "cuisines", "transitions"}


@dataclass
class AssetRecord:
    source: str
    category: str
    transparent_png: str
    gif: str | None
    size: Tuple[int, int]
    alpha_coverage: float


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source-root",
        type=Path,
        default=Path("flutter_app/assets/kitchen_images"),
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path("generated/kitchen_asset_pack_v1"),
    )
    parser.add_argument("--png-width", type=int, default=1024)
    parser.add_argument("--gif-width", type=int, default=480)
    parser.add_argument("--gif-fps", type=int, default=5)
    parser.add_argument(
        "--gif-frames",
        type=int,
        default=8,
        help="Number of frames to render per animation loop.",
    )
    parser.add_argument(
        "--gif-categories",
        default="actions,blocks,cuisines,transitions",
        help="Comma-separated source directories that should also get GIF loops.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Process only the first N files when greater than zero.",
    )
    return parser.parse_args()


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def scale_to_width(img: Image.Image, width: int) -> Image.Image:
    if img.width <= width:
        return img.copy()
    height = max(1, round(img.height * width / img.width))
    return img.resize((width, height), Image.Resampling.LANCZOS)


def estimate_background_mask(rgb: Image.Image) -> np.ndarray:
    """Return a boolean mask where True means background.

    The model assumes the image sits on a smooth, connected backdrop. It uses a
    coarse bilinear background estimate from the corners, then flood-fills
    connected pixels close to that estimate.
    """

    detect_width = min(384, rgb.width)
    detect_height = max(1, round(rgb.height * detect_width / rgb.width))
    small = rgb.resize((detect_width, detect_height), Image.Resampling.LANCZOS)
    arr = np.asarray(small).astype(np.float32)
    h, w, _ = arr.shape
    patch = max(8, min(16, min(h, w) // 16))

    corners = {
        "tl": arr[:patch, :patch].mean(axis=(0, 1)),
        "tr": arr[:patch, -patch:].mean(axis=(0, 1)),
        "bl": arr[-patch:, :patch].mean(axis=(0, 1)),
        "br": arr[-patch:, -patch:].mean(axis=(0, 1)),
    }

    ys = np.linspace(0, 1, h)[:, None, None]
    xs = np.linspace(0, 1, w)[None, :, None]
    bg = (
        corners["tl"][None, None, :] * (1 - xs) * (1 - ys)
        + corners["tr"][None, None, :] * xs * (1 - ys)
        + corners["bl"][None, None, :] * (1 - xs) * ys
        + corners["br"][None, None, :] * xs * ys
    )

    # Tolerate the soft gradient edges, but not the centered subject.
    dist = np.sqrt(((arr - bg) ** 2).sum(axis=2))
    candidate = dist < 52

    visited = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    def seed(r: int, c: int) -> None:
        if candidate[r, c] and not visited[r, c]:
            visited[r, c] = True
            queue.append((r, c))

    for x in range(w):
        seed(0, x)
        seed(h - 1, x)
    for y in range(h):
        seed(y, 0)
        seed(y, w - 1)

    while queue:
        r, c = queue.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rr, cc = r + dr, c + dc
            if 0 <= rr < h and 0 <= cc < w and candidate[rr, cc] and not visited[rr, cc]:
                visited[rr, cc] = True
                queue.append((rr, cc))

    return visited


def transparent_version(src: Path, png_width: int) -> tuple[Image.Image, float]:
    rgb = Image.open(src).convert("RGB")
    mask_small = estimate_background_mask(rgb)
    alpha = Image.fromarray((~mask_small).astype(np.uint8) * 255, mode="L").resize(
        rgb.size, Image.Resampling.NEAREST
    )
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=1))

    rgba = Image.open(src).convert("RGBA")
    rgba.putalpha(alpha)
    rgba = scale_to_width(rgba, png_width)
    alpha_arr = np.asarray(rgba.getchannel("A"))
    coverage = float((alpha_arr > 0).mean())
    return rgba, coverage


def motion_params(category: str, progress: float) -> tuple[float, int, int, float]:
    """Return scale, dx, dy, and rotation for the current frame."""

    wave = math.sin(progress * math.tau)
    pulse = 0.5 - 0.5 * math.cos(progress * math.tau)

    if category == "actions":
        return 1.0 + 0.03 * wave, int(5 * wave), int(-10 * pulse), 1.5 * wave
    if category == "blocks":
        return 1.0 + 0.025 * wave, int(4 * wave), int(-8 * pulse), 1.0 * wave
    if category == "cuisines":
        return 1.0 + 0.02 * wave, int(10 * wave), int(-6 * pulse), 0.5 * wave
    if category == "transitions":
        return 1.0 + 0.035 * wave, int(6 * wave), int(-9 * pulse), 0.8 * wave
    if category == "ingredients":
        return 1.0 + 0.015 * wave, int(3 * wave), int(-4 * pulse), 0.3 * wave
    return 1.0 + 0.02 * wave, int(4 * wave), int(-6 * pulse), 0.0


def render_motion_frame(
    source: Image.Image,
    canvas_size: tuple[int, int],
    category: str,
    frame_index: int,
    total_frames: int,
) -> Image.Image:
    progress = frame_index / float(total_frames)
    scale, dx, dy, angle = motion_params(category, progress)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))

    resized = source.resize(
        (max(1, int(source.width * scale)), max(1, int(source.height * scale))),
        Image.Resampling.LANCZOS,
    )
    rotated = resized.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    x = (canvas_size[0] - rotated.width) // 2 + dx
    y = (canvas_size[1] - rotated.height) // 2 + dy
    canvas.alpha_composite(rotated, (x, y))
    return canvas


def encode_gif(frames_dir: Path, gif_path: Path, fps: int) -> None:
    ensure_dir(gif_path.parent)
    pattern = str(frames_dir / "frame_%02d.png")
    palette = frames_dir / "palette.png"
    try:
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-framerate",
                str(fps),
                "-i",
                pattern,
                "-vf",
                "palettegen=reserve_transparent=1",
                str(palette),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-framerate",
                str(fps),
                "-i",
                pattern,
                "-i",
                str(palette),
                "-filter_complex",
                "paletteuse=dither=bayer:bayer_scale=5:alpha_threshold=128",
                str(gif_path),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    finally:
        if palette.exists():
            palette.unlink()


def motion_category_for(rel: Path, gif_categories: set[str]) -> str | None:
    rel_parent = rel.parent.as_posix()
    if rel_parent in gif_categories:
        return rel.parts[0] if rel.parts else "root"
    if len(rel.parts) >= 3 and rel.parts[0] == "sprites":
        sprite_family = rel.parts[1]
        if sprite_family in {"actions", "ingredients"}:
            return "actions" if sprite_family == "actions" else "ingredients"
    return None


def main() -> None:
    args = parse_args()
    gif_categories = {part.strip() for part in args.gif_categories.split(",") if part.strip()}

    source_root = args.source_root.resolve()
    output_root = args.output_root.resolve()
    png_root = output_root / "png"
    gif_root = output_root / "gif"
    ensure_dir(png_root)
    ensure_dir(gif_root)

    records: List[AssetRecord] = []
    source_files = sorted(source_root.rglob("*.png"))
    if args.limit > 0:
        source_files = source_files[: args.limit]

    with tempfile.TemporaryDirectory(prefix="kitchen_asset_pack_") as tmpdir:
        tmp_root = Path(tmpdir)

        for src in source_files:
            rel = src.relative_to(source_root)
            category = rel.parts[0] if rel.parts else "root"

            transparent, alpha_coverage = transparent_version(src, args.png_width)
            out_png = png_root / rel
            ensure_dir(out_png.parent)
            transparent.save(out_png)

            gif_path: Path | None = None
            motion_category = motion_category_for(rel, gif_categories)
            if motion_category is not None:
                gif_path = gif_root / rel.parent / f"{src.stem}.gif"
                frame_dir = tmp_root / rel.parent / src.stem
                ensure_dir(frame_dir)

                # Make smaller animation frames for a lightweight GIF.
                gif_source = scale_to_width(transparent, args.gif_width)
                canvas_size = gif_source.size
                for idx in range(args.gif_frames):
                    frame = render_motion_frame(
                        gif_source,
                        canvas_size,
                        category=motion_category,
                        frame_index=idx,
                        total_frames=args.gif_frames,
                    )
                    frame.save(frame_dir / f"frame_{idx:02d}.png")

                encode_gif(frame_dir, gif_path, args.gif_fps)

            records.append(
                AssetRecord(
                    source=rel.as_posix(),
                    category=category,
                    transparent_png=out_png.relative_to(output_root).as_posix(),
                    gif=gif_path.relative_to(output_root).as_posix() if gif_path else None,
                    size=transparent.size,
                    alpha_coverage=round(alpha_coverage, 4),
                )
            )

    index_path = output_root / "index.json"
    index_path.write_text(
        json.dumps(
            {
                "source_root": str(source_root),
                "output_root": str(output_root),
                "png_width": args.png_width,
                "gif_width": args.gif_width,
                "gif_fps": args.gif_fps,
                "gif_categories": sorted(gif_categories),
                "assets": [record.__dict__ for record in records],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"Wrote {len(records)} assets to {output_root}")


if __name__ == "__main__":
    main()
