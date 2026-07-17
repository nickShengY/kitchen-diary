#!/usr/bin/env python3
"""Build lightweight Kitchen Diary cooking loops from transparent image layers.

This adapts the small-toolkit shape of Anthropic's Slack GIF creator to
Kitchen Diary's needs:
- transparent-first exports for app use
- pet-character alignment via anchor-based compositing
- simple cooking motion presets
- lightweight animated WebP, APNG, GIF, or PNG sequences
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw

from kitchen_animation.alignment import composite_layer, prepare_layer
from kitchen_animation.exporters import save_animation, write_manifest
from kitchen_animation.presets import PRESETS, PRESET_ALIASES, get_preset, layer_transform


def parse_canvas(value: str) -> tuple[int, int]:
    width_str, height_str = value.lower().split("x", maxsplit=1)
    return int(width_str), int(height_str)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preset", default="idle", choices=sorted(set(PRESETS) | set(PRESET_ALIASES)))
    parser.add_argument("--source", type=Path, help="Single-layer source image.")
    parser.add_argument("--character", type=Path, help="Transparent pet character layer.")
    parser.add_argument("--food", type=Path, help="Transparent food layer.")
    parser.add_argument("--tool", type=Path, help="Transparent tool layer.")
    parser.add_argument("--background", type=Path, help="Optional background layer.")
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--name", default="kitchen-loop")
    parser.add_argument(
        "--format",
        choices=["webp", "apng", "gif", "png-sequence"],
        default=None,
    )
    parser.add_argument("--canvas", default=None, help="Canvas size like 512x512.")
    parser.add_argument("--fps", type=int, default=0)
    parser.add_argument("--duration-ms", type=int, default=0)
    parser.add_argument(
        "--remove-background",
        action="store_true",
        help="Try to cut out opaque sources before animating them.",
    )
    parser.add_argument("--write-manifest", action="store_true")
    return parser.parse_args()


def build_layers(args: argparse.Namespace) -> list:
    layers = []
    if args.background:
        layers.append(prepare_layer(args.background, "background", remove_bg=False))
    if args.character:
        layers.append(
            prepare_layer(
                args.character,
                "character",
                remove_bg=args.remove_background,
            )
        )
    if args.food:
        layers.append(
            prepare_layer(
                args.food,
                "food",
                remove_bg=args.remove_background,
            )
        )
    if args.tool:
        layers.append(
            prepare_layer(
                args.tool,
                "tool",
                remove_bg=args.remove_background,
            )
        )
    if args.source:
        layers.append(
            prepare_layer(
                args.source,
                "subject",
                remove_bg=args.remove_background,
            )
        )

    if not layers:
        raise SystemExit(
            "Provide at least one layer with --source, --character, --food, or --tool."
        )
    return layers


def draw_effect(canvas: Image.Image, preset_name: str, t: float) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    width, height = canvas.size
    resolved_preset = PRESET_ALIASES.get(preset_name, preset_name)

    if PRESETS[resolved_preset].effect == "steam":
        for index in range(3):
            phase = (t + index * 0.19) % 1.0
            x = width * (0.44 + index * 0.06 + 0.015 * math.sin(phase * math.tau))
            y_top = height * (0.40 - 0.08 * phase)
            y_bottom = height * 0.66
            draw.line(
                [(x, y_bottom), (x - 10 * math.sin(phase * math.tau), y_top)],
                fill=(255, 255, 255, round(110 * (1.0 - phase))),
                width=6,
            )

    if PRESETS[resolved_preset].effect == "sparkle":
        sparkle_phase = abs(math.sin(t * math.tau))
        sparkle_positions = [(0.32, 0.32), (0.72, 0.28), (0.76, 0.64)]
        for index, (px, py) in enumerate(sparkle_positions):
            size = 8 + round(10 * abs(math.sin((t + index * 0.17) * math.tau)))
            alpha = round(180 * sparkle_phase)
            cx = round(width * px)
            cy = round(height * py)
            draw.line(
                [(cx - size, cy), (cx + size, cy)],
                fill=(255, 215, 88, alpha),
                width=3,
            )
            draw.line(
                [(cx, cy - size), (cx, cy + size)],
                fill=(255, 215, 88, alpha),
                width=3,
            )


def render_frames(
    preset_name: str,
    layers: list,
    canvas_size: tuple[int, int],
    frame_count: int,
) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for index in range(frame_count):
        t = index / frame_count
        frame = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        for layer in layers:
            transform = layer_transform(preset_name, layer.role, t)
            composite_layer(
                frame,
                layer,
                position=transform["position"],
                scale=float(transform["scale"]),
                rotation_deg=float(transform["rotation"]),
                opacity=float(transform["opacity"]),
            )
        draw_effect(frame, preset_name, t)
        frames.append(frame)
    return frames


def main() -> None:
    args = parse_args()
    preset = get_preset(args.preset)
    output_format = args.format or preset.preferred_format
    canvas_size = parse_canvas(args.canvas) if args.canvas else preset.canvas_size
    fps = args.fps or preset.fps
    duration_ms = args.duration_ms or preset.duration_ms
    frame_count = max(2, round((duration_ms / 1000.0) * fps))

    layers = build_layers(args)
    frames = render_frames(args.preset, layers, canvas_size, frame_count)

    extension = {
        "webp": "webp",
        "apng": "png",
        "gif": "gif",
        "png-sequence": "",
    }[output_format]
    output_path = (
        args.out_dir / args.name
        if output_format == "png-sequence"
        else args.out_dir / f"{args.name}.{extension}"
    )
    save_animation(frames, output_path, fmt=output_format, fps=fps)

    if args.write_manifest:
        manifest_path = args.out_dir / f"{args.name}.json"
        write_manifest(
            manifest_path,
            {
                "preset": args.preset,
                "format": output_format,
                "canvasSize": list(canvas_size),
                "fps": fps,
                "durationMs": duration_ms,
                "frameCount": frame_count,
                "layers": [
                    {
                        "role": layer.role,
                        "path": str(layer.source_path),
                    }
                    for layer in layers
                ],
                "output": str(output_path),
            },
        )

    print(f"Saved {output_format} animation to {output_path}")


if __name__ == "__main__":
    main()
