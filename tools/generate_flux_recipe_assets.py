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
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

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
        "--output-extension",
        choices=["png", "webp"],
        default="png",
        help="File extension used when saving generated images.",
    )
    parser.add_argument(
        "--mode",
        choices=["ingredient-states", "tools", "action-frames", "dish-heroes", "mixtures", "effects", "characters", "fallbacks", "prompt-catalog", "all"],
        default="ingredient-states",
    )
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--retry-attempts",
        type=int,
        default=5,
        help="Number of attempts to make for each asset before recording it as failed.",
    )
    parser.add_argument(
        "--retry-delay-seconds",
        type=float,
        default=5.0,
        help="Delay between retry attempts for a failed asset.",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--write-prompts-jsonl", action="store_true")
    return parser.parse_args()


def stable_seed(*parts: str) -> int:
    digest = hashlib.sha256("::".join(parts).encode("utf-8")).hexdigest()
    # Gradio's seed slider follows signed int32 bounds, so keep the result in range.
    return int(digest[:8], 16) & 0x7FFFFFFF


def load_manifest(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


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
        seed = 42 if tool["id"] == "paring_knife" else stable_seed("tool", tool["id"])
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
        tool_id = action.get("toolIds", [next(iter(tools_by_id))])[0]
        tool = tools_by_id.get(tool_id, next(iter(tools_by_id.values())))
        ingredient = representative_ingredients[action["stage"]]
        asset_id = f"{action['id']}__{tool['id']}__{ingredient['id']}"
        seed = stable_seed("action", action["id"], tool["id"], ingredient["id"])
        for frame in action.get("sequence", ["complete"]):
            yield AssetTask(
                asset_id=f"{asset_id}__{frame}", family="action_frames",
                prompt=f"{build_action_prompt(action, tool, ingredient)}, {frame} keyframe",
                output_path=output_dir / "action_frames" / f"{asset_id}__{frame}.png",
                seed=stable_seed("action", action["id"], tool["id"], ingredient["id"], frame), width=1024, height=1024,
            )


def named_tasks(manifest: Dict[str, Any], key: str, family: str, output_dir: Path) -> Iterable[AssetTask]:
    for item in manifest.get(key, []):
        for frame in item.get("frames", ["hero"]):
            asset_id = f"{item['id']}__{frame}"
            yield AssetTask(asset_id, family, f"{STYLE_PREFIX}, {family.replace('_', ' ')}, {item['label']}, {frame} frame, isolated animation-ready layer, no text", output_dir / family / f"{asset_id}.png", stable_seed(family, asset_id))


def resolve_tasks(manifest: Dict[str, Any], output_dir: Path, mode: str) -> List[AssetTask]:
    if mode == "ingredient-states":
        return list(ingredient_tasks(manifest, output_dir))
    if mode == "tools":
        return list(tool_tasks(manifest, output_dir))
    if mode == "action-frames":
        return list(action_tasks(manifest, output_dir))
    if mode == "dish-heroes": return list(named_tasks(manifest, "dishHeroes", "dish_heroes", output_dir))
    if mode == "mixtures": return list(named_tasks(manifest, "mixtures", "mixtures", output_dir))
    if mode == "effects": return list(named_tasks(manifest, "effects", "effects", output_dir))
    if mode == "characters": return list(named_tasks(manifest, "characters", "characters", output_dir))
    if mode == "fallbacks": return list(named_tasks(manifest, "fallbacks", "fallbacks", output_dir))
    if mode == "prompt-catalog":
        return list(ingredient_tasks(manifest, output_dir)) + list(tool_tasks(manifest, output_dir)) + list(action_tasks(manifest, output_dir)) + list(named_tasks(manifest, "dishHeroes", "dish_heroes", output_dir)) + list(named_tasks(manifest, "mixtures", "mixtures", output_dir)) + list(named_tasks(manifest, "effects", "effects", output_dir)) + list(named_tasks(manifest, "characters", "characters", output_dir)) + list(named_tasks(manifest, "fallbacks", "fallbacks", output_dir))
    if mode == "all":
        return resolve_tasks(manifest, output_dir, "prompt-catalog")
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


def generate_with_gradio(
    tasks: List[AssetTask],
    base_url: str,
    api_name: str,
    output_extension: str,
    retry_attempts: int,
    retry_delay_seconds: float,
) -> List[Dict[str, str]]:
    client = Client(base_url, httpx_kwargs={"timeout": 600.0})
    failures: List[Dict[str, str]] = []
    for task in tasks:
        final_output_path = task.output_path.with_suffix(f".{output_extension}")
        if final_output_path.exists():
            print(f"Skipping existing {task.asset_id} -> {final_output_path}")
            continue
        final_output_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"Generating {task.asset_id} -> {final_output_path}")
        success = False
        last_error = ""
        for attempt in range(1, max(1, retry_attempts) + 1):
            try:
                result = client.predict(
                    task.prompt,
                    [],
                    "Distilled (4 steps)",
                    task.seed,
                    False,
                    task.width,
                    task.height,
                    task.num_inference_steps,
                    task.guidance_scale,
                    api_name=api_name,
                )
                image_path = result[0] if isinstance(result, (list, tuple)) else result
                if isinstance(image_path, str):
                    Path(image_path).replace(final_output_path)
                    success = True
                    break
                raise RuntimeError(
                    f"Unexpected Gradio response for {task.asset_id}: {type(result)!r}"
                )
            except Exception as exc:  # noqa: BLE001 - we want to retry any upstream failure
                last_error = f"{type(exc).__name__}: {exc}"
                print(f"  attempt {attempt} failed: {last_error}")
                if attempt < retry_attempts:
                    time.sleep(retry_delay_seconds)
                    client = Client(base_url, httpx_kwargs={"timeout": 600.0})
        if not success:
            failures.append({"asset_id": task.asset_id, "error": last_error})
    return failures


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

    failures = generate_with_gradio(
        tasks,
        args.base_url,
        args.api_name,
        args.output_extension,
        args.retry_attempts,
        args.retry_delay_seconds,
    )
    if failures:
        failed_path = args.output_dir.parent / "flux_generation_failed.json"
        failed_path.write_text(json.dumps(failures, indent=2), encoding="utf-8")
        print(f"Wrote failed asset list: {failed_path}")


if __name__ == "__main__":
    main()
