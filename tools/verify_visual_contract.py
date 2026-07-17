#!/usr/bin/env python3
"""Fast, offline validation for Kitchen Diary's complete visual manifest."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


MANIFEST = Path("asset_loader/recipe_animation_asset_manifest.v2.json")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument(
        "--asset-root",
        type=Path,
        default=Path("generated/kitchen_asset_pack_v2"),
        help="Root containing locally generated reduced-motion previews.",
    )
    return parser.parse_args()


def assert_action_previews(data: dict, asset_root: Path) -> None:
    missing: list[str] = []
    invalid: list[str] = []
    for action in data["actions"]:
        action_id = action["id"]
        path = asset_root / "animations" / "actions" / f"action_{action_id}.webp"
        if not path.exists():
            missing.append(action_id)
            continue
        image = Image.open(path)
        frame = image.convert("RGBA")
        alpha_min, alpha_max = frame.getchannel("A").getextrema()
        if image.n_frames < 2 or frame.getbbox() is None or alpha_min > 7 or alpha_max < 250:
            invalid.append(action_id)
    assert not missing, f"Missing local action previews: {', '.join(missing)}"
    assert not invalid, f"Invalid local action previews: {', '.join(invalid)}"


def main() -> None:
    args = parse_args()
    data = json.loads(args.manifest.read_text(encoding="utf-8"))
    assert data["styleGuide"]["masterSize"] == [1024, 1024]
    assert data["generationContract"]["selectionOnly"] is True
    assert len(data["ingredients"]) >= 190, len(data["ingredients"])
    assert len(data["actions"]) >= 45, len(data["actions"])
    assert all(action["sequence"] == ["start", "active", "midpoint", "complete"] for action in data["actions"])
    assert len(data["tools"]) >= 48, len(data["tools"])
    assert len(data["dishHeroes"]) >= 242, len(data["dishHeroes"])
    assert len(data["effects"]) >= 50, len(data["effects"])
    assert len(data["fallbacks"]) >= 16, len(data["fallbacks"])
    assert all(item["generic"] and item["uiLabel"].startswith("Generic representation:") for item in data["fallbacks"])
    assert_action_previews(data, args.asset_root)
    print("Visual contract valid:", {key: len(data[key]) for key in ("ingredients", "actions", "tools", "dishHeroes", "effects", "mixtures", "characters", "fallbacks")})


if __name__ == "__main__":
    main()
