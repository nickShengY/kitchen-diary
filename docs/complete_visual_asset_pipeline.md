# Complete visual asset pipeline

`asset_loader/recipe_animation_asset_manifest.v2.json` is the complete source
of truth for selectable Kitchen Diary visual assets. It contains exact named
ingredients, dessert essentials, compatible state profiles, 45 action
storyboards, tools, effects, mixtures, character poses, explicit generic
fallbacks, and every dish parsed from the Flutter catalog.

Build or refresh it after changing the app catalog:

```powershell
python asset_loader/build_complete_asset_manifest.py
python tools/verify_visual_contract.py
```

Create the deterministic FLUX prompt queue without generating images:

```powershell
python tools/generate_flux_recipe_assets.py `
  --manifest asset_loader/recipe_animation_asset_manifest.v2.json `
  --output-dir generated/kitchen_asset_pack_v2 `
  --mode prompt-catalog --dry-run --write-prompts-jsonl
```

Each action has `start`, `active`, `midpoint`, and `complete` keyframes plus a
`reducedMotion` completed poster. Export short transparent WebPs with
`tools/create_kitchen_cooking_animation.py`; its action aliases keep pivot and
motion grammar stable across the whole library.

Custom input must select the matching generic fallback and display its
`uiLabel`. It must never silently use the visual of a different named food.
