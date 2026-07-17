from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from PIL import Image


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def save_png_sequence(frames: Iterable[Image.Image], output_dir: Path) -> None:
    ensure_dir(output_dir)
    for index, frame in enumerate(frames):
        frame.save(output_dir / f"frame_{index:02d}.png")


def save_animation(
    frames: list[Image.Image],
    output_path: Path,
    fmt: str,
    fps: int,
    loop: int = 0,
) -> None:
    ensure_dir(output_path.parent)
    duration = max(1, round(1000 / max(1, fps)))

    if fmt == "png-sequence":
        save_png_sequence(frames, output_path)
        return

    if fmt == "webp":
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            format="WEBP",
            duration=duration,
            loop=loop,
            lossless=True,
            quality=86,
            method=6,
        )
        return

    if fmt == "apng":
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            format="PNG",
            duration=duration,
            loop=loop,
            disposal=2,
        )
        return

    if fmt == "gif":
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            format="GIF",
            duration=duration,
            loop=loop,
            disposal=2,
            optimize=False,
        )
        return

    raise ValueError(f"Unsupported format: {fmt}")


def write_manifest(path: Path, payload: dict) -> None:
    ensure_dir(path.parent)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
