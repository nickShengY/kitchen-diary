from __future__ import annotations

import math
from dataclasses import dataclass

from .easing import ease_in_out, interpolate, ping_pong, pulse


@dataclass(frozen=True)
class PresetSpec:
    name: str
    duration_ms: int
    fps: int
    canvas_size: tuple[int, int]
    preferred_format: str
    effect: str | None = None


PRESETS = {
    "idle": PresetSpec("idle", duration_ms=1600, fps=12, canvas_size=(512, 512), preferred_format="webp"),
    "chop": PresetSpec("chop", duration_ms=1400, fps=14, canvas_size=(512, 512), preferred_format="webp", effect="sparkle"),
    "stir": PresetSpec("stir", duration_ms=1800, fps=14, canvas_size=(512, 512), preferred_format="webp", effect="steam"),
    "whisk": PresetSpec("whisk", duration_ms=1500, fps=16, canvas_size=(512, 512), preferred_format="webp"),
    "sprinkle": PresetSpec("sprinkle", duration_ms=1400, fps=14, canvas_size=(512, 512), preferred_format="webp", effect="sparkle"),
    "simmer": PresetSpec("simmer", duration_ms=2200, fps=12, canvas_size=(512, 512), preferred_format="webp", effect="steam"),
    "plate": PresetSpec("plate", duration_ms=1800, fps=12, canvas_size=(512, 512), preferred_format="webp", effect="sparkle"),
}

# Every selectable action resolves to one small, predictable motion grammar.
# The aliases keep exports consistent while avoiding 45 near-identical loops.
PRESET_ALIASES = {
    "wash": "simmer", "peel": "chop", "trim": "chop", "halve": "chop", "slice": "chop", "dice": "chop", "mince": "chop", "julienne": "chop", "grate": "chop", "crush": "chop", "mash": "chop", "mix": "stir", "toss": "stir", "knead": "whisk", "fold": "stir", "roll": "whisk", "marinate": "stir", "bread_batter": "sprinkle", "blend": "whisk", "puree": "whisk", "saute": "stir", "stir_fry": "stir", "fry": "simmer", "deep_fry": "simmer", "sear": "simmer", "blanch": "simmer", "boil": "simmer", "poach": "simmer", "steam": "simmer", "braise": "simmer", "bake": "simmer", "roast": "simmer", "grill": "simmer", "smoke": "simmer", "toast": "simmer", "scramble": "stir", "reduce": "stir", "drizzle": "sprinkle", "garnish": "sprinkle", "plate": "plate",
}


def get_preset(name: str) -> PresetSpec:
    name = PRESET_ALIASES.get(name, name)
    if name not in PRESETS:
        supported = ", ".join(sorted(PRESETS))
        raise ValueError(f"Unsupported preset '{name}'. Choose one of: {supported}")
    return PRESETS[name]


def base_position(role: str) -> tuple[float, float]:
    positions = {
        "background": (0.5, 0.5),
        "character": (0.5, 0.92),
        "food": (0.52, 0.78),
        "tool": (0.58, 0.70),
        "subject": (0.5, 0.84),
    }
    return positions.get(role, (0.5, 0.82))


def layer_transform(preset: str, role: str, t: float) -> dict[str, float | tuple[float, float]]:
    preset = PRESET_ALIASES.get(preset, preset)
    wave = math.sin(t * math.tau)
    bob = math.sin(t * math.tau) * 0.01

    position = base_position(role)
    scale = 1.0
    rotation = 0.0
    opacity = 1.0

    if role == "background":
        return {
            "position": position,
            "scale": 1.0,
            "rotation": 0.0,
            "opacity": 1.0,
        }

    if role == "character":
        position = (position[0], position[1] + bob)
        scale = 1.0 + 0.02 * pulse(t, cycles=1.0)
        rotation = 0.8 * wave

    if role == "subject":
        position = (position[0], position[1] + bob)
        scale = 1.0 + 0.025 * pulse(t, cycles=1.0)
        rotation = 0.6 * wave

    if preset == "idle":
        if role == "food":
            scale = 1.0 + 0.02 * pulse(t)
        if role == "tool":
            rotation = 2.0 * wave

    if preset == "chop":
        stroke = ping_pong(t, cycles=2.0)
        if role == "tool":
            position = (0.60, 0.69 - 0.05 * stroke)
            rotation = interpolate(-24.0, 16.0, stroke, easing="back_out")
            scale = 1.0 + 0.04 * stroke
        elif role == "food":
            position = (0.52, 0.79 + 0.01 * stroke)
            scale = 1.0 - 0.05 * stroke
        elif role == "character":
            position = (0.5, 0.92 + 0.01 * stroke)

    if preset == "stir":
        angle = t * math.tau
        if role == "tool":
            position = (0.58 + 0.04 * math.cos(angle), 0.71 + 0.025 * math.sin(angle))
            rotation = 20.0 * math.sin(angle)
        elif role == "food":
            position = (0.52 + 0.01 * math.sin(angle), 0.79 + 0.005 * math.cos(angle))
            scale = 1.0 + 0.02 * pulse(t, cycles=2.0)

    if preset == "whisk":
        angle = t * math.tau * 1.5
        if role == "tool":
            position = (0.58 + 0.035 * math.cos(angle), 0.68 + 0.03 * math.sin(angle))
            rotation = 28.0 * math.sin(angle)
        elif role == "food":
            scale = 1.0 + 0.03 * pulse(t, cycles=2.0)
            position = (0.52, 0.79 - 0.01 * pulse(t, cycles=2.0))

    if preset == "sprinkle":
        drop = ease_in_out(t)
        if role == "tool":
            position = (0.60, 0.60 + 0.06 * drop)
            rotation = -18.0 + 24.0 * drop
        elif role == "food":
            scale = 1.0 + 0.02 * pulse(t)

    if preset == "simmer":
        if role == "food":
            position = (0.52, 0.79 + 0.01 * wave)
            scale = 1.0 + 0.025 * pulse(t, cycles=2.0)
        elif role == "character":
            position = (0.5, 0.925 + 0.008 * wave)

    if preset == "plate":
        settle = pulse(t, cycles=1.0)
        if role == "food":
            position = (0.52, 0.77 + 0.02 * (1.0 - settle))
            scale = 0.96 + 0.05 * settle
        elif role == "tool":
            position = (0.63, 0.69 + 0.02 * settle)
            rotation = 14.0 * (1.0 - settle)

    return {
        "position": position,
        "scale": scale,
        "rotation": rotation,
        "opacity": opacity,
    }
