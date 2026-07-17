#!/usr/bin/env python3
"""Export the visual manifest into lightweight web and Flutter picker bridges."""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "asset_loader/recipe_animation_asset_manifest.v2.json"
TS_OUT = ROOT / "data/visualCatalog.ts"
DART_OUT = ROOT / "flutter_app/lib/data/visual_catalog.dart"

EMOJI = {
    "vegetable": "🥬", "herb": "🌿", "spice": "🧂", "protein": "🥩",
    "seafood": "🦐", "plant_protein": "🫘", "dairy": "🥛", "grain": "🍚",
    "liquid": "💧", "fruit": "🍋", "dessert": "🧁",
}
TOOL_TYPE = {
    "prep": {"chef_knife", "paring_knife", "peeler", "grater", "whisk", "mixing_bowl", "cutting_board", "measuring_cup", "measuring_spoon", "colander", "mortar_pestle", "rolling_pin", "ladle", "wooden_spoon", "slotted_spoon", "pastry_brush", "piping_bag", "sieve", "stand_mixer", "hand_mixer", "thermometer"},
    "finish": {"serving_plate", "serving_bowl", "dessert_bowl", "glass", "cup"},
}
TOOL_ID_ALIASES = {
    "chef_knife": "knife", "mixing_bowl": "bowl", "stock_pot": "pot",
    "serving_plate": "plate",
}
ACTION_TO_TOOL = {
    "wash": "colander", "peel": "peeler", "trim": "knife", "halve": "knife", "slice": "knife", "dice": "knife", "chop": "knife", "mince": "knife", "julienne": "knife", "grate": "grater", "crush": "mortar_pestle", "mash": "bowl", "mix": "bowl", "whisk": "whisk", "stir": "wooden_spoon", "toss": "wok", "knead": "bowl", "fold": "bowl", "roll": "rolling_pin", "marinate": "bowl", "bread_batter": "bowl", "blend": "blender", "puree": "blender", "saute": "saute_pan", "stir_fry": "wok", "fry": "pan", "deep_fry": "pot", "sear": "skillet", "blanch": "pot", "boil": "pot", "simmer": "saucepan", "poach": "saucepan", "steam": "steamer", "braise": "dutch_oven", "bake": "oven", "roast": "oven", "grill": "grill", "smoke": "grill", "toast": "skillet", "scramble": "skillet", "reduce": "saucepan", "drizzle": "plate", "sprinkle": "plate", "garnish": "plate", "plate": "plate",
}
COOK_ACTIONS = {"saute", "stir_fry", "fry", "deep_fry", "sear", "blanch", "boil", "simmer", "poach", "steam", "braise", "bake", "roast", "grill", "smoke", "toast", "scramble", "reduce"}
FINISH_ACTIONS = {"drizzle", "sprinkle", "garnish", "plate"}


def load() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def ingredient(item: dict) -> dict:
    category = item["category"]
    profile = item["stateProfile"]
    props = ["selectable", "mixable"]
    if category not in {"spice", "herb", "liquid"}: props += ["solid", "choppable"]
    if category not in {"spice", "herb"}: props += ["cookable"]
    if category in {"vegetable", "fruit"}: props += ["peelable", "grateable"]
    if category == "liquid": props += ["liquid"]
    if category in {"protein", "seafood"}: props += ["meat"]
    return {"id": item["id"], "name": item["label"], "emoji": EMOJI[category], "category": category, "defaultUnit": item.get("defaultUnit", "pcs"), "physicalProperties": props, "visualStateProfile": profile, "genericFallback": False}


def tool(item: dict) -> dict:
    tool_id = TOOL_ID_ALIASES.get(item["id"], item["id"])
    kind = "prep" if tool_id in TOOL_TYPE["prep"] else "finish" if tool_id in TOOL_TYPE["finish"] else "appliance" if tool_id in {"oven", "air_fryer", "blender", "food_processor", "rice_cooker", "pressure_cooker"} else "cook"
    return {"id": tool_id, "name": item["label"], "icon": "🍳", "type": kind, "visualFallback": False}


def action(item: dict) -> dict:
    action_id = item["id"]
    return {"id": action_id, "name": item["label"], "verb": item["label"], "icon": "✨", "requiresToolId": ACTION_TO_TOOL[action_id], "requiresHeat": action_id in COOK_ACTIONS, "stage": "finish" if action_id in FINISH_ACTIONS else "cook" if action_id in COOK_ACTIONS else "prep", "validProperties": ["selectable"], "sequence": item["sequence"], "reducedMotion": item["reducedMotion"]}


def ts_literal(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2)


def dart_literal(value: object, indent: int = 0) -> str:
    pad = " " * indent
    if isinstance(value, dict):
        rows = [f"{pad}{{"]
        for key, item in value.items(): rows.append(f"{pad}  {json.dumps(key)}: {dart_literal(item, indent + 2)},")
        return "\n".join(rows + [f"{pad}}}"])
    if isinstance(value, list): return "[" + ", ".join(dart_literal(item, indent) for item in value) + "]"
    return json.dumps(value, ensure_ascii=False)


def main() -> None:
    data = load()
    ingredients = [ingredient(item) for item in data["ingredients"]]
    tools = [tool(item) for item in data["tools"]]
    actions = [action(item) for item in data["actions"]]
    states = [{"id": state["id"], "label": state["label"]} for state in data["processingStates"]]
    TS_OUT.write_text(
        "// GENERATED from asset_loader/recipe_animation_asset_manifest.v2.json.\n"
        "export const VISUAL_INGREDIENTS = " + ts_literal(ingredients) + " as const;\n"
        "export const VISUAL_TOOLS = " + ts_literal(tools) + " as const;\n"
        "export const VISUAL_ACTIONS = " + ts_literal(actions) + " as const;\n"
        "export const VISUAL_STATES = " + ts_literal(states) + " as const;\n",
        encoding="utf-8")
    DART_OUT.write_text(
        "// GENERATED from asset_loader/recipe_animation_asset_manifest.v2.json.\n"
        "// ignore_for_file: prefer_single_quotes\n"
        "class VisualCatalog {\n"
        f"  static const ingredients = {dart_literal(ingredients, 2)};\n"
        f"  static const tools = {dart_literal(tools, 2)};\n"
        f"  static const actions = {dart_literal(actions, 2)};\n"
        f"  static const states = {dart_literal(states, 2)};\n"
        f"  static const stateProfiles = {dart_literal(data['stateProfiles'], 2)};\n"
        "}\n", encoding="utf-8")
    print(f"Exported {len(ingredients)} ingredients, {len(tools)} tools, {len(actions)} actions.")


if __name__ == "__main__": main()
