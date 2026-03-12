#!/usr/bin/env python3
"""Generate recipe-animation assets through a local FLUX Gradio app.

This script targets a locally hosted FLUX app based on the Hugging Face space:
https://huggingface.co/spaces/black-forest-labs/FLUX.2-klein-4B

Expected inference signature from the original app source:
  infer(prompt, seed=42, randomize_seed=False,
        width=1024, height=1024,
        guidance_scale=4.0, num_inference_steps=12)

Typical usage:
  python tools/generate_flux_recipe_assets.py \
    --manifest asset_loader/recipe_animation_asset_manifest.json \
    --output-dir generated/flux_recipe_assets \
    --mode ingredient-states \
    --dry-run

  python tools/generate_flux_recipe_assets.py \
    --manifest asset_loader/recipe_animation_asset_manifest.json \
    --output-dir generated/flux_recipe_assets \
    --mode ingredient-states \
    --base-url http://127.0.0.1:5671 \
    --api-name /infer
"""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

try:
    from gradio_client import Client
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Install gradio_client first: pip install gradio_client pillow"
    ) from exc


STYLE_PREFIX = (
    "stylized cooking game sprite, clean mobile-game asset, "
    "three-quarter top-down camera, centered single subject, "
    "consistent scale, soft studio lighting, clean silhouette, "
    "transparent or flat neutral background, no hands, no people"
)

NEGATIVE_PROMPT = (
    "photorealistic, text, labels, watermark, logo, multiple objects, clutter, "
    "messy background, cropped object, off-center subject, dramatic shadows, blur"
)


@dataclass
class AssetTask:
    asset_id: str
    family: str
    prompt: str
    output_path: Path
    seed: int
    width: int = 1024
    height: int = 1024
    guidance_scale: float = 4.0
    num_inference_steps: int = 12


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--base-url", default="http://127.0.0.1:5671")
    parser.add_argument("--api-name", default="/infer")
    parser.add_argument(
        "--mode",
        choices=["ingredient-states", "tools", "action-frames", "prompt-catalog"],
        default="ingredient-states",
    )
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--write-prompts-jsonl", action="store_true")
    return parser.parse_args()


def stable_seed(*parts: str) -> int:
    digest = hashlib.sha256("::".join(parts).encode("utf-8")).hexdigest()
    return int(digest[:8], 16)


def load_manifest(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def state_descriptor(manifest: Dict[str, Any], state_id: str) -> str:
    for state in manifest["processingStates"]:
        if state["id"] == state_id:
            return state["descriptor"]
    return state_id.replace("_", " ")


def state_ids_for(manifest: Dict[str, Any], ingredient: Dict[str, Any]) -> List[str]:
    profile_id = ingredient["stateProfile"]
    return list(manifest["stateProfiles"][profile_id])


def build_ingredient_prompt(manifest: Dict[str, Any], ingredient: Dict[str, Any], state_id: str) -> str:
    descriptor = state_descriptor(manifest, state_id)
    return (
        f"{STYLE_PREFIX}, ingredient sprite, {ingredient['label']}, {descriptor}, "
        f"category {ingredient['category']}, isolated asset, centered composition, "
        f"exactly one ingredient subject, readable for recipe animation"
    )


def build_tool_prompt(tool: Dict[str, Any]) -> str:
    return (
        f"{STYLE_PREFIX}, kitchen tool sprite, {tool['label']}, {tool['category']} tool, "
        "isolated hero asset, centered composition, readable for cooking animation"
    )


def build_action_prompt(action: Dict[str, Any], tool: Dict[str, Any], ingredient: Dict[str, Any]) -> str:
    output_state = action.get("outputState", "processed")
    return (
        f"{STYLE_PREFIX}, cooking action keyframe, {action['label']} action, "
        f"{ingredient['label']} with {tool['label']}, output state {output_state}, "
        "single step animation frame, readable transformation, centered composition"
    )


def ingredient_tasks(manifest: Dict[str, Any], output_dir: Path) -> Iterable[AssetTask]:
    for ingredient in manifest["ingredients"]:
        for state_id in state_ids_for(manifest, ingredient):
            asset_id = f"{ingredient['id']}__{state_id}"
            seed = stable_seed("ingredient", ingredient["id"], state_id)
            yield AssetTask(
                asset_id=asset_id,
                family="ingredient_states",
                prompt=build_ingredient_prompt(manifest, ingredient, state_id),
                output_path=output_dir / "ingredient_states" / f"{asset_id}.png",
                seed=seed,
            )


def tool_tasks(manifest: Dict[str, Any], output_dir: Path) -> Iterable[AssetTask]:
    for tool in manifest["tools"]:
        seed = stable_seed("tool", tool["id"])
        yield AssetTask(
            asset_id=tool["id"],
            family="tools",
            prompt=build_tool_prompt(tool),
            output_path=output_dir / "tools" / f"{tool['id']}.png",
            seed=seed,
        )


def action_tasks(manifest: Dict[str, Any], output_dir: Path) -> Iterable[AssetTask]:
    ingredients = manifest["ingredients"]
    tools_by_id = {tool["id"]: tool for tool in manifest["tools"]}
    representative_ingredients = {
        "prep": next(item for item in ingredients if item["category"] == "vegetable"),
        "cook": next(item for item in ingredients if item["category"] == "protein"),
        "finish": next(item for item in ingredients if item["category"] == "herb"),
    }
    for action in manifest["actions"]:
        tool_id = action["toolIds"][0]
        tool = tools_by_id[tool_id]
        ingredient = representative_ingredients[action["stage"]]
        asset_id = f"{action['id']}__{tool['id']}__{ingredient['id']}"
        seed = stable_seed("action", action["id"], tool["id"], ingredient["id"])
        yield AssetTask(
            asset_id=asset_id,
            family="action_frames",
            prompt=build_action_prompt(action, tool, ingredient),
            output_path=output_dir / "action_frames" / f"{asset_id}.png",
            seed=seed,
            width=1344,
            height=768,
        )


def resolve_tasks(manifest: Dict[str, Any], output_dir: Path, mode: str) -> List[AssetTask]:
    if mode == "ingredient-states":
        return list(ingredient_tasks(manifest, output_dir))
    if mode == "tools":
        return list(tool_tasks(manifest, output_dir))
    if mode == "action-frames":
        return list(action_tasks(manifest, output_dir))
    if mode == "prompt-catalog":
        return list(ingredient_tasks(manifest, output_dir)) + list(tool_tasks(manifest, output_dir)) + list(action_tasks(manifest, output_dir))
    raise ValueError(f"Unsupported mode: {mode}")


def write_prompt_catalog(tasks: List[AssetTask], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    prompt_path = output_dir / "flux_prompt_catalog.jsonl"
    with prompt_path.open("w", encoding="utf-8") as handle:
        for task in tasks:
            handle.write(
                json.dumps(
                    {
                        "asset_id": task.asset_id,
                        "family": task.family,
                        "prompt": task.prompt,
                        "negative_prompt": NEGATIVE_PROMPT,
                        "seed": task.seed,
                        "width": task.width,
                        "height": task.height,
                        "guidance_scale": task.guidance_scale,
                        "num_inference_steps": task.num_inference_steps,
                        "output_path": str(task.output_path),
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )
    print(f"Wrote prompt catalog: {prompt_path}")


def generate_with_gradio(tasks: List[AssetTask], base_url: str, api_name: str) -> None:
    client = Client(base_url)
    for task in tasks:
        task.output_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"Generating {task.asset_id} -> {task.output_path}")
        result = client.predict(
            task.prompt,
            task.seed,
            False,
            task.width,
            task.height,
            task.guidance_scale,
            task.num_inference_steps,
            api_name=api_name,
        )
        image_path = result[0] if isinstance(result, (list, tuple)) else result
        if isinstance(image_path, str):
            Path(image_path).replace(task.output_path)
        else:
            raise RuntimeError(
                f"Unexpected Gradio response for {task.asset_id}: {type(result)!r}"
            )


def main() -> None:
    args = parse_args()
    manifest = load_manifest(args.manifest)
    tasks = resolve_tasks(manifest, args.output_dir, args.mode)

    if args.limit > 0:
        tasks = tasks[: args.limit]

    if args.write_prompts_jsonl or args.dry_run or args.mode == "prompt-catalog":
        write_prompt_catalog(tasks, args.output_dir)

    if args.dry_run or args.mode == "prompt-catalog":
        for task in tasks[: min(10, len(tasks))]:
            print(f"[{task.family}] {task.asset_id}: {task.prompt}")
        return

    generate_with_gradio(tasks, args.base_url, args.api_name)


if __name__ == "__main__":
    main()
