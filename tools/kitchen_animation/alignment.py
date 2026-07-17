from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Tuple

import numpy as np
from PIL import Image


@dataclass
class PreparedLayer:
    role: str
    source_path: Path
    image: Image.Image
    anchor: Tuple[float, float]
    fill: float


def estimate_background_mask(rgb: Image.Image) -> np.ndarray:
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

    dist = np.sqrt(((arr - bg) ** 2).sum(axis=2))
    candidate = dist < 52

    visited = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    def seed(row: int, col: int) -> None:
        if candidate[row, col] and not visited[row, col]:
            visited[row, col] = True
            queue.append((row, col))

    for x in range(w):
        seed(0, x)
        seed(h - 1, x)
    for y in range(h):
        seed(y, 0)
        seed(y, w - 1)

    while queue:
        row, col = queue.popleft()
        for d_row, d_col in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            next_row = row + d_row
            next_col = col + d_col
            if 0 <= next_row < h and 0 <= next_col < w:
                if candidate[next_row, next_col] and not visited[next_row, next_col]:
                    visited[next_row, next_col] = True
                    queue.append((next_row, next_col))

    return visited


def remove_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    if alpha.min() < 250:
        return rgba

    rgb = image.convert("RGB")
    mask_small = estimate_background_mask(rgb)
    matte = Image.fromarray((~mask_small).astype(np.uint8) * 255, mode="L").resize(
        rgb.size,
        Image.Resampling.NEAREST,
    )
    rgba.putalpha(matte)
    return rgba


def crop_to_alpha(image: Image.Image, padding: int = 10) -> Image.Image:
    alpha = np.asarray(image.getchannel("A"))
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0 or len(ys) == 0:
        return image.copy()

    left = max(0, int(xs.min()) - padding)
    top = max(0, int(ys.min()) - padding)
    right = min(image.width, int(xs.max()) + padding + 1)
    bottom = min(image.height, int(ys.max()) + padding + 1)
    return image.crop((left, top, right, bottom))


def clear_hidden_rgb(image: Image.Image) -> Image.Image:
    """Avoid colour leaks from fully transparent source pixels in WebP/APNG.

    Generative sources often retain green-screen or white backdrop RGB values
    after the alpha channel is cut. Some animation decoders expose that hidden
    colour during frame disposal, so make transparent pixels neutral before
    compositing or encoding.
    """
    rgba = image.convert("RGBA")
    pixels = np.asarray(rgba).copy()
    pixels[pixels[:, :, 3] < 8, :3] = 0
    return Image.fromarray(pixels, mode="RGBA")


def anchor_for_role(role: str) -> tuple[float, float]:
    if role == "character":
        return (0.5, 0.96)
    if role == "food":
        return (0.5, 0.92)
    if role == "tool":
        return (0.5, 0.58)
    if role == "background":
        return (0.5, 0.5)
    return (0.5, 0.9)


def fill_for_role(role: str) -> float:
    if role == "character":
        return 0.52
    if role == "food":
        return 0.28
    if role == "tool":
        return 0.30
    if role == "background":
        return 1.0
    return 0.72


def prepare_layer(path: Path, role: str, remove_bg: bool) -> PreparedLayer:
    image = Image.open(path).convert("RGBA")
    if remove_bg:
        image = remove_background(image)
    image = clear_hidden_rgb(crop_to_alpha(image))
    return PreparedLayer(
        role=role,
        source_path=path,
        image=image,
        anchor=anchor_for_role(role),
        fill=fill_for_role(role),
    )


def composite_layer(
    canvas: Image.Image,
    layer: PreparedLayer,
    position: tuple[float, float],
    scale: float = 1.0,
    rotation_deg: float = 0.0,
    opacity: float = 1.0,
    fill_override: float | None = None,
) -> None:
    canvas_width, canvas_height = canvas.size
    target_fill = fill_override if fill_override is not None else layer.fill
    target_max_dim = max(1.0, min(canvas_width, canvas_height) * target_fill * scale)
    source_max_dim = max(layer.image.width, layer.image.height)
    resize_scale = target_max_dim / max(1.0, source_max_dim)

    resized = layer.image.resize(
        (
            max(1, round(layer.image.width * resize_scale)),
            max(1, round(layer.image.height * resize_scale)),
        ),
        Image.Resampling.LANCZOS,
    )
    if opacity < 1.0:
        alpha = resized.getchannel("A").point(lambda value: round(value * opacity))
        resized.putalpha(alpha)

    anchor_x = resized.width * layer.anchor[0]
    anchor_y = resized.height * layer.anchor[1]
    pad = int(max(resized.width, resized.height) * 1.8)
    pad = max(pad, resized.width + 32, resized.height + 32)
    padded = Image.new("RGBA", (pad, pad), (0, 0, 0, 0))
    center_x = pad // 2
    center_y = pad // 2
    padded.alpha_composite(
        resized,
        (round(center_x - anchor_x), round(center_y - anchor_y)),
    )

    if abs(rotation_deg) > 0.01:
        padded = padded.rotate(
            rotation_deg,
            resample=Image.Resampling.BICUBIC,
            center=(center_x, center_y),
        )

    target_x = round(position[0] * canvas_width - center_x)
    target_y = round(position[1] * canvas_height - center_y)
    canvas.alpha_composite(padded, (target_x, target_y))
