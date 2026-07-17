# Pet Cooking Animation Pipeline

This workflow adapts the small animation-toolkit idea from Anthropic's `slack-gif-creator` to Kitchen Diary's cooking UI.

## What changes for Kitchen Diary

- Prefer transparent `webp` first, then APNG, then GIF.
- Keep the pet chef anchored to a fixed baseline so motion feels natural.
- Generate separate `character`, `tool`, and `food` layers whenever possible.
- Use `imagegen` for the still art, then animate the stills with `tools/create_kitchen_cooking_animation.py`.

## Generation rules

- Keep the camera fixed to the repo's three-quarter top-down cooking view.
- Keep one pet character family per recipe pack: same species, hat, apron, face, and paw proportions.
- Remove the background before animation. Transparent masters are the default.
- Keep the character centered and aligned. Do not change the baseline between related frames.
- Keep loops short: usually 1.4 to 2.2 seconds.
- Use soft, readable motion. Avoid cinematic camera moves.

## Preferred asset stack

1. `character` layer: transparent pet chef master
2. `tool` layer: isolated tool
3. `food` layer: isolated ingredient or plated result
4. optional `background` layer: only when a scene is really needed

If the art arrives as one flattened image, use `--remove-background` as a fallback, but the best result comes from layered transparent masters.

## Prompt source

Use [tools/kitchen_animation/prompt_templates.json](/C:/Projects/KitchenDiary/tools/kitchen_animation/prompt_templates.json) with the built-in `imagegen` workflow.

For cuisine-aware generation, also read [recipe_animation_asset_manifest.json](/C:/Projects/KitchenDiary/asset_loader/recipe_animation_asset_manifest.json). It now includes:

- `cuisineProfiles`: regional staples, preferred actions, and signature dish anchors
- `dishFamilies`: reusable families like `stir_fry`, `curry`, `noodle_bowl`, `grill_plate`, and `dumpling_plate`

The key invariants are:

- same pet character family across related animations
- transparent background
- fixed baseline near the bottom of the square canvas
- consistent tool grip and camera angle

## CLI

Single-layer motion:

```bash
python tools/create_kitchen_cooking_animation.py \
  --preset chop \
  --source flutter_app/assets/kitchen_images/transitions/onion_raw_to_chopped.png \
  --remove-background \
  --format webp \
  --out-dir generated/pet_loops \
  --name onion-chop \
  --write-manifest
```

Layered pet loop:

```bash
python tools/create_kitchen_cooking_animation.py \
  --preset stir \
  --character generated/pet_layers/cat-chef.png \
  --food generated/pet_layers/onion-bowl.png \
  --tool generated/pet_layers/wood-spoon.png \
  --format webp \
  --out-dir generated/pet_loops \
  --name cat-stir-onion \
  --write-manifest
```

## Presets

- `idle`: soft breathing or hover motion
- `chop`: snappy tool swing plus slight food squash
- `stir`: circular tool path plus steam
- `whisk`: faster circular mixing motion
- `sprinkle`: top-down sprinkle gesture with sparkles
- `simmer`: gentle bounce with steam
- `plate`: settle-and-reveal finish

## App-facing recommendation

- Use animated `webp` for the default mobile asset.
- Use GIF only when broad compatibility matters more than alpha quality.
- Use PNG sequences when the Flutter surface needs frame-by-frame control.
