#!/usr/bin/env python
"""Generate Kitchen Diary Modular Animation Assets using Qwen image model.

Usage example:
  python generate_kitchen_images_qwen.py \
    --kitchen-json flutter_app/assets/data/kitchen_data.json \
    --output-dir generated/kitchen_images \
    --types ingredient tool action cuisine state sprite

This script supports the modular cooking animation system:
- Generates ingredient icons for each state (raw, chopped, cooked, etc.)
- Creates transformation sprite sheets for animations
- Builds action sequence sprites for smooth transitions
- Generates tool-in-action images
- Creates composable block preview images
- Outputs Wan 2.2-ready video prompts for ingredient transformations

New v2.0 Features:
- Ingredient state images (raw → chopped → fried, etc.)
- Sprite sheet generation for animations
- Transformation sequence images
- Composable block previews
- Enhanced video prompts for step transitions

Requirements (on your HPC / local machine):
  pip install 'diffusers[torch]' transformers accelerate safetensors pillow
  # and make sure Qwen/Qwen-Image weights are available
"""

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

import torch
from diffusers import DiffusionPipeline, ZImagePipeline

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore

ASPECT_RATIOS = {
    "1:1": (1328, 1328),
    "16:9": (1664, 928),
    "4:3": (1472, 1136),
    "sprite_64": (64, 64),
    "sprite_96": (96, 96),
    "sprite_128": (128, 128),
    "sprite_sheet_4x4": (512, 512),
    "sprite_sheet_6x2": (768, 256),
}

# Quality tier configurations - can be overridden by kitchen_data.json
DEFAULT_QUALITY_TIERS = {
    "preview": {"imageSize": 256, "frames": 4, "inferenceSteps": 20},
    "standard": {"imageSize": 512, "frames": 8, "inferenceSteps": 40},
    "high": {"imageSize": 768, "frames": 12, "inferenceSteps": 60},
    "ultra": {"imageSize": 1024, "frames": 16, "inferenceSteps": 80},
}

# Default negative prompts by category
DEFAULT_NEGATIVE_PROMPTS = {
    "default": "no photorealism, no 3d render, no text, no captions, no watermark, no logo, blurry, low quality, distorted",
    "character": "no photorealism, no 3d render, no text, no watermark, disproportionate hands, extra fingers, deformed, ugly",
    "food": "no photorealism, no text, no watermark, unappetizing, rotten, moldy, burnt beyond recognition, raw when should be cooked",
    "tool": "no photorealism, no text, no watermark, rusty, broken, unsafe, unrealistic proportions",
    "sprite": "no photorealism, no text, inconsistent frames, frame bleeding, misaligned sprites, different styles between frames",
}


def get_quality_settings(kitchen: Dict[str, Any], quality: str = "standard") -> Dict[str, Any]:
    """Get quality settings from kitchen_data.json or defaults."""
    generation_config = kitchen.get("generationConfig", {})
    quality_tiers = generation_config.get("qualityTiers", DEFAULT_QUALITY_TIERS)
    return quality_tiers.get(quality, DEFAULT_QUALITY_TIERS["standard"])


def get_negative_prompt(kitchen: Dict[str, Any], category: str = "default") -> str:
    """Get the appropriate negative prompt for a category."""
    generation_config = kitchen.get("generationConfig", {})
    negative_prompts = generation_config.get("negativePromptVariants", DEFAULT_NEGATIVE_PROMPTS)
    return negative_prompts.get(category, DEFAULT_NEGATIVE_PROMPTS["default"])


def get_color_harmony(kitchen: Dict[str, Any], category: str) -> Dict[str, Any]:
    """Get color harmony palette for an action category."""
    generation_config = kitchen.get("generationConfig", {})
    color_harmonies = generation_config.get("colorHarmonies", {})
    return color_harmonies.get(category, {
        "primary": "#FF6B6B",
        "secondary": "#4ECDC4",
        "accent": "#FFE66D",
        "gradient": ["#FF6B6B", "#4ECDC4"]
    })


def get_generation_hints(kitchen: Dict[str, Any], ingredient_category: str) -> Dict[str, str]:
    """Get category-specific generation hints for better image quality."""
    generation_config = kitchen.get("generationConfig", {})
    generation_hints = generation_config.get("generationHints", {})
    
    # Map ingredient categories to hint categories
    category_mapping = {
        "vegetable": "vegetables",
        "fruit": "vegetables",
        "meat": "meat",
        "seafood": "seafood",
        "dairy": "dairy",
        "spice": "spices",
        "condiment": "spices",
        "grain": "grains",
        "liquid": "dairy",
    }
    
    hint_category = category_mapping.get(ingredient_category, "vegetables")
    return generation_hints.get(hint_category, {
        "styleModifier": "fresh and appetizing",
        "lightingPreference": "soft natural lighting",
        "textureEmphasis": "clear textures visible"
    })


def get_seasonal_theme(kitchen: Dict[str, Any], season: Optional[str] = None) -> Dict[str, Any]:
    """Get seasonal theme palette and elements."""
    import datetime
    
    if season is None:
        # Auto-detect season from current month
        month = datetime.datetime.now().month
        if month in [3, 4, 5]:
            season = "spring"
        elif month in [6, 7, 8]:
            season = "summer"
        elif month in [9, 10, 11]:
            season = "autumn"
        else:
            season = "winter"
    
    generation_config = kitchen.get("generationConfig", {})
    seasonal_themes = generation_config.get("seasonalThemes", {})
    return seasonal_themes.get(season, {
        "palette": ["#FF6B6B", "#4ECDC4", "#FFE66D"],
        "decorativeElements": [],
        "mood": "warm and inviting"
    })


def get_advanced_generation_config(kitchen: Dict[str, Any]) -> Dict[str, Any]:
    """Get advanced generation configuration for optimal image quality."""
    generation_config = kitchen.get("generationConfig", {})
    advanced = generation_config.get("advancedGeneration", {})
    
    return {
        "promptWeighting": advanced.get("promptWeighting", {
            "style": 1.2,
            "subject": 1.0,
            "background": 0.8,
            "effects": 0.9,
        }),
        "multiPassRefinement": advanced.get("multiPassRefinement", {
            "enabled": False,
            "passes": 2,
            "refinementStrength": 0.3,
        }),
        "styleConsistency": advanced.get("styleConsistency", {
            "seedLocking": True,
            "colorPaletteEnforcement": True,
            "outlineThicknessRange": [2, 4],
        }),
        "batchOptimization": advanced.get("batchOptimization", {
            "groupSimilarPrompts": True,
            "cacheBaseImages": True,
            "parallelGeneration": 4,
        }),
    }


def apply_prompt_weighting(prompt: str, weights: Dict[str, float]) -> str:
    """Apply prompt weighting for better generation control.
    
    Uses syntax like (keyword:weight) for emphasis control.
    """
    # Extract weight values
    style_weight = weights.get("style", 1.0)
    subject_weight = weights.get("subject", 1.0)
    background_weight = weights.get("background", 0.8)
    effects_weight = weights.get("effects", 0.9)
    
    # Apply weights to key prompt segments
    weighted_parts = []
    parts = prompt.split(", ")
    
    for part in parts:
        part_lower = part.lower()
        
        # Style-related terms
        if any(term in part_lower for term in ["cartoon", "style", "cute", "pastel"]):
            if style_weight != 1.0:
                weighted_parts.append(f"({part}:{style_weight:.1f})")
            else:
                weighted_parts.append(part)
        # Subject-related terms
        elif any(term in part_lower for term in ["icon", "image", "showing"]):
            if subject_weight != 1.0:
                weighted_parts.append(f"({part}:{subject_weight:.1f})")
            else:
                weighted_parts.append(part)
        # Background-related terms
        elif any(term in part_lower for term in ["background", "gradient", "centered"]):
            if background_weight != 1.0:
                weighted_parts.append(f"({part}:{background_weight:.1f})")
            else:
                weighted_parts.append(part)
        # Effects-related terms
        elif any(term in part_lower for term in ["effect", "particle", "sparkle", "steam"]):
            if effects_weight != 1.0:
                weighted_parts.append(f"({part}:{effects_weight:.1f})")
            else:
                weighted_parts.append(part)
        else:
            weighted_parts.append(part)
    
    return ", ".join(weighted_parts)


def group_similar_prompts(prompts: List[Dict[str, Any]]) -> List[List[Dict[str, Any]]]:
    """Group similar prompts for batch optimization."""
    groups: Dict[str, List[Dict[str, Any]]] = {}
    
    for prompt_info in prompts:
        # Create a key based on shared characteristics
        category = prompt_info.get("category", "default")
        state = prompt_info.get("state", "default")
        key = f"{category}_{state}"
        
        if key not in groups:
            groups[key] = []
        groups[key].append(prompt_info)
    
    return list(groups.values())


def get_style_preset(kitchen: Dict[str, Any], style_id: str = "cute_cartoon") -> Dict[str, Any]:
    """Get a style preset configuration for generation."""
    generation_config = kitchen.get("generationConfig", {})
    style_presets = generation_config.get("stylePresets", {})
    
    # Default cute cartoon style
    default_style = {
        "id": "cute_cartoon",
        "name": "Cute Cartoon",
        "promptModifiers": {
            "style": "cute cartoon style, kawaii, adorable",
            "colors": "soft pastel colors, warm tones",
            "outlines": "thick black outlines, clean edges",
            "shading": "flat shading with subtle gradients"
        }
    }
    
    return style_presets.get(style_id, default_style)


def apply_style_preset(prompt: str, style_preset: Dict[str, Any]) -> str:
    """Apply a style preset to a prompt."""
    modifiers = style_preset.get("promptModifiers", {})
    
    # Build style suffix
    style_parts = []
    if modifiers.get("style"):
        style_parts.append(modifiers["style"])
    if modifiers.get("colors"):
        style_parts.append(modifiers["colors"])
    if modifiers.get("outlines"):
        style_parts.append(modifiers["outlines"])
    if modifiers.get("shading"):
        style_parts.append(modifiers["shading"])
    
    style_suffix = ", ".join(style_parts)
    
    # Replace generic style terms in prompt with preset style
    # Remove existing style references and add preset style
    prompt_parts = prompt.split(", ")
    filtered_parts = [
        p for p in prompt_parts
        if not any(term in p.lower() for term in [
            "cartoon style", "pastel", "outlines", "shading"
        ])
    ]
    
    return ", ".join(filtered_parts) + ", " + style_suffix


def get_export_format_config(kitchen: Dict[str, Any], format_id: str) -> Dict[str, Any]:
    """Get export format configuration."""
    generation_config = kitchen.get("generationConfig", {})
    export_formats = generation_config.get("exportFormats", {})
    return export_formats.get(format_id, {})


class GenerationType(Enum):
    """Types of assets that can be generated."""
    INGREDIENT_ICON = "ingredient_icon"
    INGREDIENT_STATE = "ingredient_state"
    INGREDIENT_TRANSITION = "ingredient_transition"
    TOOL_HERO = "tool_hero"
    TOOL_IN_ACTION = "tool_in_action"
    ACTION_STEP = "action_step"
    ACTION_SEQUENCE = "action_sequence"
    CUISINE_SCENE = "cuisine_scene"
    COMPOSABLE_BLOCK = "composable_block"
    FINISHED_DISH = "finished_dish"
    SPRITE_SHEET = "sprite_sheet"


@dataclass
class GenerationTask:
    """A single image generation task."""
    task_type: GenerationType
    output_path: Path
    prompt: str
    negative_prompt: str
    width: int
    height: int
    metadata: Dict[str, Any]


class QwenImageError(Exception):
    """Custom exception for Qwen image generation errors."""


def load_kitchen_data(path: Path) -> Dict[str, Any]:
    """Load the kitchen_data.json file as a dict."""
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def load_qwen_pipeline(model_name: str, device: Optional[str] = None):
    """Load the local diffusion pipeline (Z-Image Turbo or other Diffusers model)."""
    if device is None:
        if torch.cuda.is_available():
            device = "cuda"
        else:
            device = "cpu"

    if torch.cuda.is_available():
        torch_dtype = torch.bfloat16
    else:
        torch_dtype = torch.float32

    # Use the dedicated ZImagePipeline when targeting Z-Image models
    if "Z-Image" in model_name or "Z-Image-Turbo" in model_name:
        pipe = ZImagePipeline.from_pretrained(
            model_name,
            torch_dtype=torch_dtype,
            low_cpu_mem_usage=False,
        )
    else:
        pipe = DiffusionPipeline.from_pretrained(
            model_name,
            torch_dtype=torch_dtype,
        )

    pipe = pipe.to(device)
    pipe.set_progress_bar_config(disable=False)
    return pipe, device


def generate_image(
    pipe: DiffusionPipeline,
    prompt: str,
    *,
    negative_prompt: Optional[str],
    width: int,
    height: int,
    num_inference_steps: int,
    true_cfg_scale: float,
    seed: Optional[int],
    device: str,
):
    """Run a single text-to-image generation."""
    generator = None
    if seed is not None:
        generator = torch.Generator(device=device).manual_seed(seed)

    if isinstance(pipe, ZImagePipeline):
        # Z-Image Turbo uses guidance_scale instead of true_cfg_scale
        result = pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            width=width,
            height=height,
            num_inference_steps=num_inference_steps,
            guidance_scale=true_cfg_scale,
            generator=generator,
        )
    else:
        result = pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            width=width,
            height=height,
            num_inference_steps=num_inference_steps,
            true_cfg_scale=true_cfg_scale,
            generator=generator,
        )

    return result.images[0]


def substitute_template(template: str, values: Dict[str, Any]) -> str:
    """Very simple {{placeholder}} substitution for our templates.

    We deliberately avoid full templating engines and just replace
    occurrences of {{key}} with the given values.
    """
    result = template
    for key, value in values.items():
        placeholder = "{{" + key + "}}"
        result = result.replace(placeholder, str(value))
    return result


def generate_ingredient_icons(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate ingredient icon images from the ingredientIcon template."""
    template = image_templates.get("ingredientIcon")
    if not template:
        print("No ingredientIcon template in generationConfig.imageTemplates, skipping.")
        return

    ingredients = kitchen.get("ingredients") or []
    print(f"Generating ingredient icons for {len(ingredients)} ingredients...")

    for idx, ing in enumerate(ingredients):
        ing_id = ing.get("id")
        if not ing_id:
            continue

        values = {
            "category": ing.get("category", "ingredient"),
            "emoji": ing.get("emoji", ""),
            "name": ing.get("name", ing_id),
        }
        prompt = substitute_template(template, values)
        filename = f"{ing_id}.png"
        dest = output_dir / "ingredients" / filename

        if dest.exists():
            print(f"[ingredient] Skipping {ing_id}, file already exists at {dest}")
            continue

        print(f"[ingredient] {ing_id}: {prompt}")
        if dry_run:
            continue

        if pipe is None:
            raise QwenImageError("Pipeline is not initialized")

        width, height = ASPECT_RATIOS["1:1"]
        seed = (base_seed + idx) if base_seed is not None else None
        image = generate_image(
            pipe,
            prompt,
            negative_prompt=(
                "no photorealism, no 3d render, no text, no captions, "
                "no watermark, no logo"
            ),
            width=width,
            height=height,
            num_inference_steps=steps,
            true_cfg_scale=true_cfg_scale,
            seed=seed,
            device=device,
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)


def generate_tool_heroes(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate hero images for tools from the toolHero template."""
    template = image_templates.get("toolHero")
    if not template:
        print("No toolHero template in generationConfig.imageTemplates, skipping.")
        return

    tools = kitchen.get("tools") or []
    print(f"Generating hero images for {len(tools)} tools...")

    for idx, tool in enumerate(tools):
        tool_id = tool.get("animationKey") or tool.get("id")
        if not tool_id:
            continue

        values = {
            "name": tool.get("name", tool_id),
            "icon": tool.get("icon", ""),
        }
        prompt = substitute_template(template, values)
        filename = f"{tool_id}.png"
        dest = output_dir / "tools" / filename

        if dest.exists():
            print(f"[tool] Skipping {tool_id}, file already exists at {dest}")
            continue

        print(f"[tool] {tool_id}: {prompt}")
        if dry_run:
            continue

        if pipe is None:
            raise QwenImageError("Pipeline is not initialized")

        width, height = ASPECT_RATIOS["4:3"]
        seed = (base_seed + idx) if base_seed is not None else None
        image = generate_image(
            pipe,
            prompt,
            negative_prompt=(
                "no photorealism, no 3d render, no text, no captions, "
                "no watermark, no logo"
            ),
            width=width,
            height=height,
            num_inference_steps=steps,
            true_cfg_scale=true_cfg_scale,
            seed=seed,
            device=device,
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)


def generate_action_steps(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate step images for actions from the actionStep template."""
    template = image_templates.get("actionStep")
    if not template:
        print("No actionStep template in generationConfig.imageTemplates, skipping.")
        return

    actions = kitchen.get("actions") or []
    tools = kitchen.get("tools") or []
    tools_by_id = {t.get("id"): t for t in tools if t.get("id")}

    print(f"Generating step images for {len(actions)} actions...")

    for idx, action in enumerate(actions):
        action_id = action.get("animationKey") or action.get("id")
        if not action_id:
            continue

        tool_id = action.get("requiresToolId")
        tool = tools_by_id.get(tool_id) if tool_id else None
        tool_name = tool.get("name") if tool else (tool_id or "tool")

        values = {
            "actionName": action.get("name", action_id),
            "toolName": tool_name,
        }
        prompt = substitute_template(template, values)
        filename = f"{action_id}.png"
        dest = output_dir / "actions" / filename

        if dest.exists():
            print(f"[action] Skipping {action_id}, file already exists at {dest}")
            continue

        print(f"[action] {action_id}: {prompt}")
        if dry_run:
            continue

        if pipe is None:
            raise QwenImageError("Pipeline is not initialized")

        width, height = ASPECT_RATIOS["16:9"]
        seed = (base_seed + idx) if base_seed is not None else None
        image = generate_image(
            pipe,
            prompt,
            negative_prompt=(
                "no photorealism, no 3d render, no text, no captions, "
                "no watermark, no logo"
            ),
            width=width,
            height=height,
            num_inference_steps=steps,
            true_cfg_scale=true_cfg_scale,
            seed=seed,
            device=device,
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)


def generate_cuisine_scenes(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate cuisine scene images from the cuisineScene template."""
    template = image_templates.get("cuisineScene")
    if not template:
        print("No cuisineScene template in generationConfig.imageTemplates, skipping.")
        return

    cuisines = kitchen.get("cuisineCategories") or []
    print(f"Generating cuisine scenes for {len(cuisines)} cuisines...")

    for idx, cuisine in enumerate(cuisines):
        cuisine_id = cuisine.get("id")
        if not cuisine_id:
            continue

        cuisine_name = cuisine.get("name", cuisine_id)
        dish_name = (
            cuisine.get("signatureDish")
            or cuisine.get("exampleDish")
            or cuisine.get("dishName")
            or cuisine_name
        )

        values = {
            "cuisineName": cuisine_name,
            "dishName": dish_name,
        }
        prompt = substitute_template(template, values)
        filename = f"{cuisine_id}.png"
        dest = output_dir / "cuisines" / filename

        if dest.exists():
            print(f"[cuisine] Skipping {cuisine_id}, file already exists at {dest}")
            continue

        print(f"[cuisine] {cuisine_id}: {prompt}")
        if dry_run:
            continue

        if pipe is None:
            raise QwenImageError("Pipeline is not initialized")

        width, height = ASPECT_RATIOS["4:3"]
        seed = (base_seed + idx) if base_seed is not None else None
        image = generate_image(
            pipe,
            prompt,
            negative_prompt=(
                "no photorealism, no 3d render, no text, no captions, "
                "no watermark, no logo"
            ),
            width=width,
            height=height,
            num_inference_steps=steps,
            true_cfg_scale=true_cfg_scale,
            seed=seed,
            device=device,
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)


def generate_ingredient_states(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate ingredient images for each transformation state.
    
    This creates images like tomato_raw.png, tomato_chopped.png, tomato_fried.png
    for use in the modular animation system. Uses enhanced visual descriptors
    including colorShift, textureHint, lightingHint, and particleHint.
    """
    template = image_templates.get("ingredientState")
    if not template:
        print("No ingredientState template in generationConfig.imageTemplates, skipping.")
        return

    ingredients = kitchen.get("ingredients") or []
    ingredient_states = kitchen.get("ingredientStates") or {}
    
    total_tasks = sum(
        len(ing.get("allowedStates") or ["raw"]) 
        for ing in ingredients
    )
    print(f"Generating {total_tasks} ingredient state images...")

    task_idx = 0
    for ing in ingredients:
        ing_id = ing.get("id")
        if not ing_id:
            continue

        ing_name = ing.get("name", ing_id)
        ing_emoji = ing.get("emoji", "")
        ing_category = ing.get("category", "ingredient")
        allowed_states = ing.get("allowedStates") or ["raw"]
        color_palette = ing.get("colorPalette") or []
        color_hint = color_palette[0] if color_palette else "natural"
        
        # Get category-specific generation hints
        category_hints = get_generation_hints(kitchen, ing_category)

        for state_id in allowed_states:
            state_info = ingredient_states.get(state_id) or {}
            state_suffix = state_info.get("suffix", f"_{state_id}")
            visual_modifier = state_info.get("visualModifier", state_id)
            color_shift = state_info.get("colorShift", "none")
            texture_hint = state_info.get("textureHint", "")
            lighting_hint = state_info.get("lightingHint", "soft lighting")
            particle_hint = state_info.get("particleHint", "")

            # Build an enhanced prompt with all visual details and category hints
            enhanced_prompt = _build_enhanced_state_prompt(
                ing_name=ing_name,
                ing_emoji=ing_emoji,
                ing_category=ing_category,
                state_id=state_id,
                visual_modifier=visual_modifier,
                color_shift=color_shift,
                color_hint=color_hint,
                texture_hint=texture_hint,
                lighting_hint=lighting_hint,
                particle_hint=particle_hint,
                generation_hints=category_hints,
            )

            filename = f"{ing_id}{state_suffix}.png"
            dest = output_dir / "ingredient_states" / filename

            if dest.exists():
                print(f"[state] Skipping {ing_id}_{state_id}, file already exists")
                task_idx += 1
                continue

            print(f"[state] {ing_id}_{state_id}: {enhanced_prompt[:80]}...")
            if dry_run:
                task_idx += 1
                continue

            if pipe is None:
                raise QwenImageError("Pipeline is not initialized")

            width, height = ASPECT_RATIOS["1:1"]
            seed = (base_seed + task_idx) if base_seed is not None else None
            image = generate_image(
                pipe,
                enhanced_prompt,
                negative_prompt=(
                    "no photorealism, no 3d render, no text, no captions, "
                    "no watermark, no logo, no background clutter, blurry, "
                    "low quality, distorted, inconsistent style"
                ),
                width=width,
                height=height,
                num_inference_steps=steps,
                true_cfg_scale=true_cfg_scale,
                seed=seed,
                device=device,
            )
            dest.parent.mkdir(parents=True, exist_ok=True)
            image.save(dest)
            task_idx += 1


def _build_enhanced_state_prompt(
    ing_name: str,
    ing_emoji: str,
    ing_category: str,
    state_id: str,
    visual_modifier: str,
    color_shift: str,
    color_hint: str,
    texture_hint: str,
    lighting_hint: str,
    particle_hint: str,
    generation_hints: Optional[Dict[str, str]] = None,
) -> str:
    """Build an enhanced prompt with all visual details for better generation quality."""
    
    # Get category-specific hints
    style_mod = ""
    lighting_pref = ""
    texture_emphasis = ""
    
    if generation_hints:
        style_mod = generation_hints.get("styleModifier", "")
        lighting_pref = generation_hints.get("lightingPreference", "")
        texture_emphasis = generation_hints.get("textureEmphasis", "")
    
    # Base prompt structure
    parts = [
        f"Cute cartoon {ing_category} icon of {ing_name}",
        f"in {state_id} state",
        f"({visual_modifier})",
    ]
    
    # Add category-specific style modifier
    if style_mod:
        parts.append(style_mod)
    
    # Add color information
    if color_shift and color_shift != "none":
        parts.append(f"with {color_shift}")
    if color_hint and color_hint != "natural":
        parts.append(f"color palette hints of {color_hint}")
    
    # Add texture details (combine with category emphasis)
    if texture_hint:
        texture_desc = texture_hint
        if texture_emphasis:
            texture_desc = f"{texture_hint}, {texture_emphasis}"
        parts.append(f"showing {texture_desc}")
    elif texture_emphasis:
        parts.append(f"showing {texture_emphasis}")
    
    # Add lighting (prefer category-specific if available)
    if lighting_pref:
        parts.append(lighting_pref)
    elif lighting_hint:
        parts.append(lighting_hint)
    
    # Add particle/effect hints
    if particle_hint and particle_hint != "none":
        parts.append(f"with subtle {particle_hint} effects")
    
    # Add style consistency
    parts.append("flat cartoon style, thick outlines, pastel colors")
    parts.append("centered on clean gradient background")
    parts.append("no text, consistent with CuteCartoonKitchenV2 style")
    
    return ", ".join(parts)


def _build_enhanced_transition_prompt(
    ing_name: str,
    ing_emoji: str,
    from_state: str,
    to_state: str,
    from_visual: str,
    to_visual: str,
    action_name: str,
    verb: str,
    camera_angle: str,
    motion_blur: str,
    visual_cues: list,
) -> str:
    """Build an enhanced prompt for transformation sequences with camera and motion details."""
    
    # Map camera angles to prompt descriptions
    camera_descriptions = {
        "top-down-45": "45-degree overhead perspective showing action from above",
        "close-up-angle": "close-up detailed view of the transformation",
        "side-profile": "side view profile showing the cutting action",
        "overhead": "bird's eye view from directly above",
        "three-quarter": "three-quarter view showing depth",
        "dynamic-angle": "dynamic camera angle capturing motion",
        "low-angle-drama": "dramatic low angle with heat effects rising",
        "extreme-close": "extreme close-up on texture changes",
        "action-track": "motion-tracked following the action",
        "surface-level": "surface-level view of bubbling liquid",
        "peaceful-overhead": "peaceful overhead showing gentle cooking",
        "ethereal-angle": "soft ethereal angle with steam effects",
        "oven-interior": "warm interior oven perspective",
        "rotating-hero": "rotating hero shot showcasing all sides",
        "flame-backlit": "backlit by flames for dramatic effect",
        "transparent-side": "side view through transparent container",
        "wok-action": "dynamic wok cooking action shot",
        "chef-pov": "chef point-of-view looking down at plate",
        "macro-detail": "macro lens detail of finishing touches",
        "slow-motion-pour": "slow-motion capture of liquid drizzle",
        "overhead-rain": "overhead view of particles falling",
        "time-lapse": "time-lapse style showing gradual change",
    }
    
    # Map motion blur to descriptions
    motion_descriptions = {
        "linear-vertical": "vertical motion blur on cutting action",
        "cross-hatch": "cross-hatching motion blur for precision cuts",
        "arc-sweep": "sweeping arc motion blur",
        "staccato-blur": "rapid staccato motion blur",
        "spiral": "spiral motion blur on peeling action",
        "up-down-rapid": "rapid up-down motion blur",
        "circular-swirl": "circular swirling motion blur",
        "figure-eight": "figure-eight whisking motion",
        "subtle-shimmer": "subtle shimmer effect",
        "heat-distortion": "heat distortion blur",
        "smoke-trails": "smoke trail motion",
        "parabolic-trail": "parabolic arc trails",
        "steam-column": "rising steam column blur",
        "soft-steam": "soft steam diffusion",
        "diffuse-mist": "diffuse misty blur",
        "heat-shimmer": "heat shimmer distortion",
        "slow-rotate": "slow rotation blur",
        "flame-flicker": "flickering flame motion",
        "radial-spin": "radial spinning blur",
        "rapid-toss": "rapid tossing motion",
        "gentle-place": "gentle placing motion",
        "scatter-fall": "scattered falling motion",
        "liquid-trail": "liquid trail motion",
        "gentle-scatter": "gentle scattering motion",
    }
    
    camera_desc = camera_descriptions.get(camera_angle, f"{camera_angle} camera angle")
    motion_desc = motion_descriptions.get(motion_blur, f"{motion_blur} motion effect")
    
    parts = [
        f"Professional sprite strip of {ing_name} {verb} transformation",
        f"4 sequential keyframes: (1) {from_state} state ({from_visual})",
        f"(2) {action_name} action beginning",
        f"(3) mid-transformation with {motion_desc}",
        f"(4) {to_state} state ({to_visual}) with completion sparkle",
    ]
    
    # Add camera angle
    parts.append(camera_desc)
    
    # Add visual cues
    if visual_cues:
        cues_text = ", ".join(visual_cues[:3])  # Limit to top 3 cues
        parts.append(f"showing {cues_text} effects")
    
    # Add style consistency
    parts.extend([
        "cute cartoon style",
        "consistent lighting across all frames",
        "soft pastel background gradient",
        "animation-ready with clear frame boundaries",
        "no text",
        "CuteCartoonKitchenV2 style",
    ])
    
    return ", ".join(parts)


def generate_transformation_sequences(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate transformation sequence images showing before→after states.
    
    These are horizontal strips showing the transformation process,
    useful for creating smooth animations between states.
    Uses enhanced action metadata for camera angles, motion blur, and visual cues.
    """
    template = image_templates.get("ingredientTransition")
    if not template:
        print("No ingredientTransition template in generationConfig.imageTemplates, skipping.")
        return

    ingredients = kitchen.get("ingredients") or []
    action_transforms = kitchen.get("actionTransformations") or {}
    ingredient_states = kitchen.get("ingredientStates") or {}
    actions = kitchen.get("actions") or []
    
    # Build transformation pairs with enhanced metadata
    transforms = []
    for action in actions:
        action_id = action.get("id")
        if not action_id:
            continue
        transform = action_transforms.get(action_id)
        if not transform:
            continue
        
        input_states = transform.get("inputStates") or []
        output_state = transform.get("outputState")
        if not input_states or not output_state:
            continue
        
        # Extract enhanced metadata
        camera_angle = transform.get("cameraAngle", "dynamic-angle")
        motion_blur = transform.get("motionBlur", "subtle")
        visual_cues = transform.get("visualCues", [])
        color_accent = transform.get("colorAccent", "#FF6B6B")
            
        transforms.append({
            "actionId": action_id,
            "actionName": action.get("name", action_id),
            "verb": transform.get("verb", action_id),
            "fromState": input_states[0],
            "toState": output_state,
            "cameraAngle": camera_angle,
            "motionBlur": motion_blur,
            "visualCues": visual_cues,
            "colorAccent": color_accent,
        })

    print(f"Generating transformation sequences for {len(ingredients)} ingredients × {len(transforms)} actions...")

    task_idx = 0
    for ing in ingredients:
        ing_id = ing.get("id")
        if not ing_id:
            continue

        ing_name = ing.get("name", ing_id)
        ing_emoji = ing.get("emoji", "")
        allowed_states = set(ing.get("allowedStates") or ["raw"])

        for transform in transforms:
            from_state = transform["fromState"]
            to_state = transform["toState"]
            
            # Skip if ingredient doesn't support these states
            if from_state not in allowed_states or to_state not in allowed_states:
                continue

            # Get state visual details
            from_state_info = ingredient_states.get(from_state, {})
            to_state_info = ingredient_states.get(to_state, {})

            # Build enhanced prompt with action metadata
            enhanced_prompt = _build_enhanced_transition_prompt(
                ing_name=ing_name,
                ing_emoji=ing_emoji,
                from_state=from_state,
                to_state=to_state,
                from_visual=from_state_info.get("visualModifier", from_state),
                to_visual=to_state_info.get("visualModifier", to_state),
                action_name=transform["actionName"],
                verb=transform["verb"],
                camera_angle=transform["cameraAngle"],
                motion_blur=transform["motionBlur"],
                visual_cues=transform["visualCues"],
            )
            
            filename = f"{ing_id}_{from_state}_to_{to_state}.png"
            dest = output_dir / "transitions" / filename

            if dest.exists():
                print(f"[transition] Skipping {filename}, file already exists")
                task_idx += 1
                continue

            print(f"[transition] {filename}: {enhanced_prompt[:60]}...")
            if dry_run:
                task_idx += 1
                continue

            if pipe is None:
                raise QwenImageError("Pipeline is not initialized")

            # Use wider aspect ratio for transition sequences
            width, height = ASPECT_RATIOS["16:9"]
            seed = (base_seed + task_idx) if base_seed is not None else None
            image = generate_image(
                pipe,
                enhanced_prompt,
                negative_prompt=(
                    "no photorealism, no 3d render, no text, no captions, "
                    "no watermark, no logo"
                ),
                width=width,
                height=height,
                num_inference_steps=steps,
                true_cfg_scale=true_cfg_scale,
                seed=seed,
                device=device,
            )
            dest.parent.mkdir(parents=True, exist_ok=True)
            image.save(dest)
            task_idx += 1


def generate_composable_blocks(
    kitchen: Dict[str, Any],
    image_templates: Dict[str, str],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate preview images for composable cooking blocks.
    
    These are used as thumbnails/icons for the animation composer UI.
    """
    template = image_templates.get("composableBlock")
    if not template:
        print("No composableBlock template in generationConfig.imageTemplates, skipping.")
        return

    blocks = kitchen.get("composableBlocks") or {}
    print(f"Generating {len(blocks)} composable block previews...")

    for idx, (block_id, block) in enumerate(blocks.items()):
        block_name = block.get("name", block_id)
        block_desc = block.get("description", "")

        values = {
            "blockName": block_name,
            "blockDescription": block_desc,
        }
        prompt = substitute_template(template, values)
        filename = f"{block_id}.png"
        dest = output_dir / "blocks" / filename

        if dest.exists():
            print(f"[block] Skipping {block_id}, file already exists")
            continue

        print(f"[block] {block_id}: {prompt[:60]}...")
        if dry_run:
            continue

        if pipe is None:
            raise QwenImageError("Pipeline is not initialized")

        width, height = ASPECT_RATIOS["1:1"]
        seed = (base_seed + idx) if base_seed is not None else None
        image = generate_image(
            pipe,
            prompt,
            negative_prompt=(
                "no photorealism, no 3d render, no text, no captions, "
                "no watermark, no logo"
            ),
            width=width,
            height=height,
            num_inference_steps=steps,
            true_cfg_scale=true_cfg_scale,
            seed=seed,
            device=device,
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)


def generate_sprite_sheets(
    kitchen: Dict[str, Any],
    sprite_templates: Dict[str, Any],
    output_dir: Path,
    *,
    pipe=None,
    device: str = "cpu",
    steps: int = 40,
    true_cfg_scale: float = 4.0,
    base_seed: Optional[int] = None,
    dry_run: bool = False,
) -> None:
    """Generate sprite sheets for animations.
    
    Creates multi-frame sprite sheets that can be used for
    smooth animations in the Flutter app.
    """
    if not sprite_templates:
        print("No spriteSheetTemplates in generationConfig, skipping sprite generation.")
        return

    ingredients = kitchen.get("ingredients") or []
    actions = kitchen.get("actions") or []
    tools = kitchen.get("tools") or []
    tools_by_id = {t.get("id"): t for t in tools if t.get("id")}

    # Generate ingredient transformation sprite sheets
    ing_transform_template = sprite_templates.get("ingredientTransform")
    if ing_transform_template:
        template_str = ing_transform_template.get("template", "")
        frame_size = ing_transform_template.get("frameSize", [64, 64])
        
        print(f"Generating ingredient transformation sprite sheets...")
        
        for idx, ing in enumerate(ingredients[:5]):  # Limit for demo
            ing_id = ing.get("id")
            ing_name = ing.get("name", ing_id)
            emoji = ing.get("emoji", "")
            
            # Generate a simple raw→chopped transformation
            values = {
                "name": ing_name,
                "emoji": emoji,
                "fromState": "raw",
                "toState": "chopped",
                "actionName": "chopping",
            }
            prompt = substitute_template(template_str, values)
            filename = f"{ing_id}_transform_raw_chopped.png"
            dest = output_dir / "sprites" / "ingredients" / filename

            if dest.exists():
                print(f"[sprite] Skipping {filename}, file already exists")
                continue

            print(f"[sprite] {filename}: {prompt[:50]}...")
            if dry_run:
                continue

            if pipe is None:
                raise QwenImageError("Pipeline is not initialized")

            # Sprite sheet dimensions
            width, height = ASPECT_RATIOS["sprite_sheet_4x4"]
            seed = (base_seed + idx) if base_seed is not None else None
            image = generate_image(
                pipe,
                prompt,
                negative_prompt=(
                    "no photorealism, no 3d render, no text, no captions, "
                    "no watermark, no logo, inconsistent style"
                ),
                width=width,
                height=height,
                num_inference_steps=steps,
                true_cfg_scale=true_cfg_scale,
                seed=seed,
                device=device,
            )
            dest.parent.mkdir(parents=True, exist_ok=True)
            image.save(dest)

    # Generate cooking action sprite sheets
    action_template = sprite_templates.get("cookingAction")
    if action_template:
        template_str = action_template.get("template", "")
        
        print(f"Generating cooking action sprite sheets...")
        
        for idx, action in enumerate(actions[:8]):  # Limit for demo
            action_id = action.get("id")
            action_name = action.get("name", action_id)
            tool_id = action.get("requiresToolId")
            tool = tools_by_id.get(tool_id) if tool_id else None
            tool_name = tool.get("name") if tool else (tool_id or "tool")
            
            # Get particle effects for this action
            action_transforms = kitchen.get("actionTransformations") or {}
            transform = action_transforms.get(action_id) or {}
            anim_type_id = transform.get("animationType", "")
            anim_types = kitchen.get("animationTypes") or {}
            anim_type = anim_types.get(anim_type_id) or {}
            particle_effects = ", ".join(anim_type.get("particleEffects", []))

            values = {
                "actionName": action_name,
                "toolName": tool_name,
                "particleEffects": particle_effects or "sparkles",
            }
            prompt = substitute_template(template_str, values)
            filename = f"action_{action_id}.png"
            dest = output_dir / "sprites" / "actions" / filename

            if dest.exists():
                print(f"[sprite] Skipping {filename}, file already exists")
                continue

            print(f"[sprite] {filename}: {prompt[:50]}...")
            if dry_run:
                continue

            if pipe is None:
                raise QwenImageError("Pipeline is not initialized")

            width, height = ASPECT_RATIOS["sprite_sheet_6x2"]
            seed = (base_seed + idx + 100) if base_seed is not None else None
            image = generate_image(
                pipe,
                prompt,
                negative_prompt=(
                    "no photorealism, no 3d render, no text, no captions, "
                    "no watermark, no logo, inconsistent frames"
                ),
                width=width,
                height=height,
                num_inference_steps=steps,
                true_cfg_scale=true_cfg_scale,
                seed=seed,
                device=device,
            )
            dest.parent.mkdir(parents=True, exist_ok=True)
            image.save(dest)


def build_video_prompts(
    kitchen: Dict[str, Any],
    video_templates: Dict[str, str],
    output_path: Path,
) -> None:
    """Build Wan 2.2-ready video prompts from videoTemplates and save as JSON.

    This does not call any video API. It just materializes prompts so that
    a separate Wan 2.2 script or tool can consume them.
    """
    prompts: Dict[str, Any] = {
        "actions": {},
        "cuisines": {},
    }

    actions = kitchen.get("actions") or []
    tools = kitchen.get("tools") or []
    tools_by_id = {t.get("id"): t for t in tools if t.get("id")}

    action_template = video_templates.get("actionLoop")
    if action_template:
        for action in actions:
            action_id = action.get("animationKey") or action.get("id")
            if not action_id:
                continue

            tool_id = action.get("requiresToolId")
            tool = tools_by_id.get(tool_id) if tool_id else None
            tool_name = tool.get("name") if tool else (tool_id or "tool")

            values = {
                "actionName": action.get("name", action_id),
                "toolName": tool_name,
            }
            prompt = substitute_template(action_template, values)
            prompts["actions"][action_id] = prompt

    cuisines = kitchen.get("cuisineCategories") or []
    cuisine_template = video_templates.get("cuisineIntro")
    if cuisine_template:
        for cuisine in cuisines:
            cuisine_id = cuisine.get("id")
            if not cuisine_id:
                continue

            cuisine_name = cuisine.get("name", cuisine_id)
            dish_name = (
                cuisine.get("signatureDish")
                or cuisine.get("exampleDish")
                or cuisine.get("dishName")
                or cuisine_name
            )

            values = {
                "cuisineName": cuisine_name,
                "dishName": dish_name,
            }
            prompt = substitute_template(cuisine_template, values)
            prompts["cuisines"][cuisine_id] = prompt

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(prompts, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"Video prompts written to {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Kitchen Diary Modular Animation Assets using Qwen image model.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate all asset types
  python generate_kitchen_images_qwen.py --types all

  # Generate only ingredient states and transitions
  python generate_kitchen_images_qwen.py --types state transition

  # Dry run to see what would be generated
  python generate_kitchen_images_qwen.py --dry-run --types sprite block

Asset Types:
  ingredient  - Basic ingredient icons
  tool        - Kitchen tool hero images
  action      - Cooking action step images
  cuisine     - Cuisine scene backgrounds
  state       - Ingredient state images (raw, chopped, fried, etc.)
  transition  - Transformation sequence images
  block       - Composable cooking block previews
  sprite      - Animation sprite sheets
  all         - Generate all asset types
""",
    )
    parser.add_argument(
        "--kitchen-json",
        type=Path,
        default=Path("flutter_app/assets/data/kitchen_data.json"),
        help="Path to kitchen_data.json",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("generated/kitchen_images"),
        help="Directory to save generated images",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="Qwen/Qwen-Image",
        help="Model name or path for the local Qwen image pipeline.",
    )
    parser.add_argument(
        "--device",
        type=str,
        default=None,
        help="Torch device (e.g. 'cuda', 'cuda:0', 'cpu'). Defaults to cuda if available.",
    )
    parser.add_argument(
        "--types",
        nargs="+",
        choices=["ingredient", "tool", "action", "cuisine", "state", "transition", "block", "sprite", "all"],
        default=["ingredient", "tool", "action", "cuisine"],
        help="Which asset types to generate (default: ingredient tool action cuisine)",
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=40,
        help="Number of diffusion steps (num_inference_steps).",
    )
    parser.add_argument(
        "--true-cfg-scale",
        type=float,
        default=4.0,
        help="Guidance scale (true_cfg_scale).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Base random seed. Per-image seeds are offset from this.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print prompts, do not run the diffusion pipeline",
    )
    parser.add_argument(
        "--video-prompts-json",
        type=Path,
        default=Path("generated/kitchen_video_prompts.json"),
        help=(
            "Where to save Wan 2.2-ready video prompts JSON. "
            "No video API calls are made."
        ),
    )
    parser.add_argument(
        "--no-video-prompts",
        action="store_true",
        help="Skip emitting video prompts JSON.",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output",
    )
    parser.add_argument(
        "--quality",
        "-q",
        type=str,
        choices=["preview", "standard", "high", "ultra"],
        default="standard",
        help="Quality tier affecting image size and inference steps (default: standard)",
    )
    parser.add_argument(
        "--use-quality-presets",
        action="store_true",
        help="Override --steps with quality tier settings from kitchen_data.json",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    print("=" * 60)
    print("Kitchen Diary Modular Animation Asset Generator v2.0")
    print("=" * 60)

    kitchen = load_kitchen_data(args.kitchen_json)
    gen_cfg = kitchen.get("generationConfig") or {}
    image_templates = gen_cfg.get("imageTemplates") or {}
    video_templates = gen_cfg.get("videoTemplates") or {}
    sprite_templates = gen_cfg.get("spriteSheetTemplates") or {}

    # Get quality settings
    quality_settings = get_quality_settings(kitchen, args.quality)
    
    # Override steps if using quality presets
    inference_steps = args.steps
    if args.use_quality_presets:
        inference_steps = quality_settings.get("inferenceSteps", args.steps)
        print(f"\nUsing quality tier '{args.quality}': {quality_settings}")

    # Expand 'all' to include all types
    types_to_generate = args.types
    if "all" in types_to_generate:
        types_to_generate = [
            "ingredient", "tool", "action", "cuisine",
            "state", "transition", "block", "sprite"
        ]

    print(f"\nGenerating asset types: {', '.join(types_to_generate)}")
    print(f"Quality tier: {args.quality} (steps: {inference_steps})")
    print(f"Output directory: {args.output_dir}")
    print(f"Dry run: {args.dry_run}")
    print("-" * 60)

    if args.dry_run:
        pipe = None
        device = args.device or ("cuda" if torch.cuda.is_available() else "cpu")
    else:
        pipe, device = load_qwen_pipeline(args.model, args.device)

    # Original generation functions
    if "ingredient" in types_to_generate:
        print("\n[1/8] Generating ingredient icons...")
        generate_ingredient_icons(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "tool" in types_to_generate:
        print("\n[2/8] Generating tool hero images...")
        generate_tool_heroes(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "action" in types_to_generate:
        print("\n[3/8] Generating action step images...")
        generate_action_steps(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "cuisine" in types_to_generate:
        print("\n[4/8] Generating cuisine scenes...")
        generate_cuisine_scenes(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    # New modular animation generation functions
    if "state" in types_to_generate:
        print("\n[5/8] Generating ingredient state images...")
        generate_ingredient_states(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "transition" in types_to_generate:
        print("\n[6/8] Generating transformation sequences...")
        generate_transformation_sequences(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "block" in types_to_generate:
        print("\n[7/8] Generating composable block previews...")
        generate_composable_blocks(
            kitchen,
            image_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    if "sprite" in types_to_generate:
        print("\n[8/8] Generating sprite sheets...")
        generate_sprite_sheets(
            kitchen,
            sprite_templates,
            args.output_dir,
            pipe=pipe,
            device=device,
            steps=args.steps,
            true_cfg_scale=args.true_cfg_scale,
            base_seed=args.seed,
            dry_run=args.dry_run,
        )

    # Build video prompts for Wan 2.2
    if not args.no_video_prompts and video_templates:
        print("\nBuilding video prompts for Wan 2.2...")
        build_video_prompts(kitchen, video_templates, args.video_prompts_json)

    print("\n" + "=" * 60)
    print("Generation complete!")
    print(f"Output saved to: {args.output_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
