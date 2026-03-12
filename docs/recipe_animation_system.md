# Recipe Animation System

## Builder direction

The recipe builder should be animation-first, not text-step-first.

The authoring flow should be:
1. Add ingredients, spices, sauces, and liquids.
2. Pick the exact inputs for one step.
3. Pick an optional prep action such as wash, peel, slice, dice, mince, grate, mix, or marinate.
4. Pick an optional cooking action such as saute, fry, boil, simmer, steam, bake, roast, or grill.
5. Set tool, heat, time, water level, and result label.
6. Save that step as a graph node that can compile into both animation and readable instructions.

That is the mental model used in the updated Flutter builder pass: ingredients first, guided step second, low-level operation editor third.

## Canonical recipe model

The long-term recipe model should use `procedure` as the only source of truth.

Each step should store:
- `inputLotIds`
- `prepAction`
- `cookAction`
- `toolId`
- `temperature`
- `duration`
- `waterLevel`
- `resultLotIds`
- `resultLabel`
- `animationHints`

The old compiled text steps should be derived at read time or build time, not stored as a second editable truth.

## Asset requirements

For animation to feel Overcooked-like and easy to read, every generated asset should follow the same visual contract:
- Camera: fixed three-quarter top-down angle or fixed orthographic top view.
- Framing: single subject centered, 8 to 12 percent padding, no cropping.
- Background: transparent or flat neutral backdrop for extraction.
- Lighting: soft studio lighting, no dramatic shadows.
- Style: one consistent stylized food illustration language.
- Scale: object fills roughly 70 percent of frame unless it is a tiny spice pile.
- Orientation: consistent default orientation per item family.
- No hands, no people, no text, no labels, no plates unless the state is plated.

## Asset library structure

Use four asset families:
- Ingredient state sprites: `ingredient_id + state_id`
- Tool sprites: `tool_id`
- Action keyframes: `action_id + tool_id + ingredient_family`
- Result sprites: named outputs such as `stir_fry_base`, `soup_base`, `sauce_base`, `finished_dish`

## Consistency strategy for Flux

Use one global art-direction prefix for every prompt.

Lock consistency with:
- deterministic seed families per ingredient id
- a single base style phrase reused everywhere
- one fixed background rule
- one fixed camera rule
- one fixed composition rule
- explicit processed-state descriptors such as diced, sliced, minced, peeled, seared, simmered

For best results, generate in this order:
1. Raw ingredient hero.
2. Processed states for the same ingredient using the same seed family.
3. Tool heroes.
4. Action frames combining one ingredient family plus one tool.
5. Result/output assets.

## Current blockers in this repo

These still need attention beyond the builder UI improvements:
- `flutter_app/assets/data/kitchen_data.json` is malformed and cannot be trusted as the source of truth.
- The recipe system still stores both `procedure` and compiled legacy `steps`.
- The catalog is still frontend-owned instead of backend-owned.
- The current animation compiler flattens graph richness into sequential steps.

## Files added for this system

- `asset_loader/recipe_animation_asset_manifest.json`
- `tools/generate_flux_recipe_assets.py`

The manifest is the canonical v1 animation asset library. The Python script consumes that manifest and calls the local FLUX app on `http://127.0.0.1:5671` using the Gradio interface exposed by the Hugging Face app.
