from __future__ import annotations

import math


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def linear(t: float) -> float:
    return clamp01(t)


def ease_in_out(t: float) -> float:
    t = clamp01(t)
    return 0.5 - 0.5 * math.cos(t * math.pi)


def ease_out(t: float) -> float:
    t = clamp01(t)
    return 1.0 - (1.0 - t) * (1.0 - t)


def back_out(t: float) -> float:
    t = clamp01(t)
    c1 = 1.70158
    c3 = c1 + 1.0
    return 1.0 + c3 * pow(t - 1.0, 3) + c1 * pow(t - 1.0, 2)


def pulse(t: float, cycles: float = 1.0) -> float:
    return 0.5 - 0.5 * math.cos(clamp01(t) * math.tau * cycles)


def ping_pong(t: float, cycles: float = 1.0) -> float:
    return abs(math.sin(clamp01(t) * math.tau * cycles))


def interpolate(start: float, end: float, t: float, easing: str = "linear") -> float:
    easing_map = {
        "linear": linear,
        "ease_in_out": ease_in_out,
        "ease_out": ease_out,
        "back_out": back_out,
    }
    eased = easing_map.get(easing, linear)(t)
    return start + (end - start) * eased
