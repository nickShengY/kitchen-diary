#!/usr/bin/env python3
"""Build the complete Kitchen Diary visual-library manifest.

This keeps the large, evolving visual contract in one reproducible source of
truth. It intentionally describes generation work; it does not pretend that a
generic picture is an exact food asset.
"""
from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path


INGREDIENTS = {
    "vegetable": "Onion, Garlic, Shallot, Scallion, Leek, Ginger, Tomato, Potato, Sweet Potato, Carrot, Celery, Mushroom, Bell Pepper, Chili Pepper, Broccoli, Cauliflower, Cabbage, Napa Cabbage, Spinach, Lettuce, Bok Choy, Kale, Zucchini, Eggplant, Cucumber, Corn, Green Beans, Peas, Radish, Beet, Asparagus, Bean Sprouts",
    "herb": "Basil, Parsley, Cilantro, Mint, Thyme, Rosemary, Oregano, Dill",
    "spice": "Salt, Black Pepper, Generic Pepper, Chili Flakes, Paprika, Cumin, Turmeric, Curry Powder, Coriander, Garam Masala, Cinnamon, Nutmeg, Sumac, Za'atar, Bay Leaf",
    "protein": "Chicken, Chicken Breast, Chicken Thigh, Turkey, Beef, Ground Beef, Beef Slices, Steak, Pork, Pork Belly, Pork Chop, Bacon, Sausage, Lamb, Lamb Shoulder",
    "seafood": "Fish, White Fish, Salmon, Tuna, Shrimp, Squid",
    "plant_protein": "Tofu, Tempeh, Chickpeas, Lentils, Black Beans, Kidney Beans, Soybean, Edamame",
    "dairy": "Egg, Milk, Cream, Yogurt, Butter, Generic Cheese, Mozzarella, Cheddar, Parmesan, Paneer",
    "grain": "Rice, White Rice, Brown Rice, Jasmine Rice, Basmati Rice, Pasta, Spaghetti, Penne, Macaroni, Noodles, Ramen Noodles, Udon, Rice Noodles, Bread, Bread Slice, Bun, Pita, Naan, Tortilla, Flour, Wheat, Oats, Quinoa, Couscous, Cereal, Yeast, Cornstarch",
    "liquid": "Water, Broth, Stock, Wine, Olive Oil, Vegetable Oil, Sesame Oil, Generic Oil, Soy Sauce, Vinegar, Coconut Milk, Fish Sauce, Oyster Sauce, Tomato Paste, Honey, Ketchup, Mayonnaise, Mustard",
    "fruit": "Apple, Lemon, Lime, Orange, Banana, Strawberry, Blueberry, Mango, Pineapple, Grape, Pear, Peach, Avocado",
    "dessert": "Cocoa, Chocolate, White Chocolate, Milk Chocolate, Dark Chocolate, Vanilla, Vanilla Extract, Baking Powder, Baking Soda, Powdered Sugar, Brown Sugar, Granulated Sugar, Gelatin, Agar, Pastry Dough, Pie Dough, Puff Pastry, Phyllo, Cake Batter, Brownie Batter, Cookie Dough, Cream Cheese, Mascarpone, Condensed Milk, Evaporated Milk, Custard, Ice Cream Base, Sorbet Base, Caramel, Almond, Walnut, Pecan, Pistachio, Hazelnut, Coconut, Dates, Raisins, Mochi, Rice Flour, Sprinkles, Whipped Cream, Syrup, Fruit Glaze",
}

STATES = [
    ("raw", "whole and unprocessed"), ("washed", "clean with visible moisture droplets"),
    ("peeled", "skin removed and flesh exposed"), ("trimmed", "inedible ends removed"),
    ("halved", "two clean halves"), ("quartered", "four wedge-like pieces"),
    ("wedged", "thick wedges"), ("sliced", "thin even slices"), ("diced", "small uniform cubes"),
    ("chopped", "rough chopped pieces"), ("minced", "very fine pieces"), ("julienned", "thin matchsticks"),
    ("grated", "fine shredded strands"), ("crushed", "broken and lightly smashed"), ("mashed", "soft mashed texture"),
    ("zested", "fine aromatic zest"), ("juiced", "fresh liquid with pulp cues"), ("sifted", "fine aerated powder"),
    ("cracked", "shell or exterior cleanly broken"), ("whisked", "smooth aerated mixture"), ("mixed", "cohesive combined mixture"),
    ("blended", "smooth blended texture"), ("pureed", "silky thick puree"), ("kneaded", "elastic worked dough"),
    ("folded", "gently layered mixture"), ("rolled", "evenly rolled sheet or coil"), ("shaped", "formed portion"),
    ("marinated", "visibly coated in marinade"), ("breaded", "crisp crumb or batter coating"),
    ("pickled", "brined translucent texture"), ("fermented", "matured, textured surface"),
    ("sauteed", "lightly browned with retained moisture"), ("stir_fried", "glossy wok-cooked edges"),
    ("shallow_fried", "crisp shallow-fry crust"), ("deep_fried", "puffed golden crisp crust"),
    ("seared", "deep caramelized crust"), ("blanched", "bright tender surface"), ("boiled", "softened by boiling"),
    ("simmered", "gently cooked in liquid"), ("poached", "delicately cooked in liquid"), ("steamed", "tender and moist"),
    ("braised", "tender in reduced cooking liquid"), ("baked", "oven-cooked with browned surface"),
    ("roasted", "caramelized edges"), ("grilled", "structural grill marks and char"), ("smoked", "smoke-kissed surface"),
    ("toasted", "crisp golden surface"), ("melted", "soft glossy melt"), ("browned", "even browned surface"),
    ("caramelized", "deep glossy caramel structure"), ("reduced", "thickened concentrated liquid"),
    ("scrambled", "soft egg curds"), ("whipped", "light stable peaks"), ("wilted", "softened leaf structure"),
    ("sauced", "even sauce coating"), ("drizzled", "thin visible drizzle"), ("sprinkled", "light topping distribution"),
    ("garnished", "finished herb or topping placement"), ("plated", "ready-to-serve presentation"),
    ("crispy", "structurally crisp exterior"), ("tender", "soft yielding structure"), ("juicy", "visible moisture retained"),
    ("thickened", "spoon-coating consistency"), ("set", "firm set structure"), ("golden", "golden crust"),
    ("lightly_charred", "small dark char patches"), ("fully_cooked", "cooked opaque center"),
]

TOOLS = "Chef Knife, Paring Knife, Peeler, Grater, Whisk, Mixing Bowl, Cutting Board, Measuring Cup, Measuring Spoon, Colander, Mortar and Pestle, Spatula, Tongs, Sauté Pan, Skillet, Wok, Stock Pot, Saucepan, Dutch Oven, Grill, Oven, Steamer, Air Fryer, Blender, Food Processor, Serving Plate, Rolling Pin, Baking Sheet, Cake Pan, Pie Tart Pan, Muffin Tray, Roasting Tray, Ladle, Wooden Spoon, Slotted Spoon, Pastry Brush, Piping Bag, Sieve, Stand Mixer, Hand Mixer, Rice Cooker, Pressure Cooker, Thermometer, Grill Grate, Skewers, Serving Bowl, Dessert Bowl, Glass, Cup"
ACTIONS = "Wash, Peel, Trim, Halve, Slice, Dice, Chop, Mince, Julienne, Grate, Crush, Mash, Mix, Whisk, Stir, Toss, Knead, Fold, Roll, Marinate, Bread Batter, Blend, Puree, Sauté, Stir Fry, Fry, Deep Fry, Sear, Blanch, Boil, Simmer, Poach, Steam, Braise, Bake, Roast, Grill, Smoke, Toast, Scramble, Reduce, Drizzle, Sprinkle, Garnish, Plate"
MIXTURES = "Chopped Vegetable Mixture, Aromatic Base, Marinated Protein, Batter, Dough, Pastry Dough, Sauce Base, Curry Base, Soup Base, Stock Broth Base, Stew Base, Stir Fry Mixture, Fried Mixture, Rice Mixture, Noodle Mixture, Salad Mixture, Filling, Custard, Cream Frosting, Reduced Sauce, Finished Plated Dish"
EFFECTS = "Burner Off, Low Flame, Medium Flame, High Flame, Electric Induction Glow, Oven Preheating Glow, Oven Active Glow, Grill Flame, Hot Coals, Flare Up, Warm Pan Shimmer, Browning Progression, Char Progression, Droplets, Rinsing Stream, Pour, Splash, Pot Filling, Low Water Level, Medium Water Level, High Water Level, Submerged Ingredients, Gentle Simmer, Rolling Boil, Draining, Condensation, Oil Drizzle, Pan Coating, Shallow Fry Level, Deep Fry Level, Sizzle Droplets, Sauce Pour, Sauce Coating, Thickening, Reduction, Glaze, Syrup Drizzle, Steam, Smoke, Bubbles, Sizzle, Sparks, Knife Glint, Mixing Swirl, Whisking Spiral, Blender Vortex, Ingredient Fall, Wok Toss, Spice Sprinkle, Flour Dust, Melt, Finished Food Shine"
CHARACTERS = "Idle, Thinking Choosing, Washing, Chopping, Mixing, Whisking, Stirring, Tossing Wok, Frying, Checking Pot, Opening Oven, Grilling, Blending, Tasting, Plating, Celebrating Completion, Warning Error, Burn Smoke Reaction"
FALLBACKS = "Unknown Vegetable, Unknown Fruit, Unknown Herb Spice, Unknown Protein, Unknown Seafood, Unknown Grain Noodle, Unknown Dairy, Unknown Liquid Sauce, Unknown Dessert Ingredient, Unknown Mixed Result, Generic Cut Transformation, Generic Wet Cooking Transformation, Generic Dry Heat Transformation, Generic Frying Transformation, Generic Mixing Transformation, Generic Plating Result"


def slug(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "_", normalized.lower()).strip("_").replace("_and_", "_")


def words(csv: str) -> list[str]:
    return [item.strip() for item in csv.split(",")]


def profile_for(category: str, name: str) -> str:
    if category == "dessert": return "dessert"
    if category in {"spice", "herb"}: return "seasoning"
    if category in {"liquid"}: return "liquid"
    if category in {"protein", "seafood", "plant_protein"}: return "protein"
    if category == "dairy": return "dairy"
    if category == "grain": return "dough" if any(x in name.lower() for x in ("flour", "yeast", "bread", "naan", "pita", "tortilla")) else "grain"
    if category == "fruit": return "produce"
    return "produce"


PROFILES = {
    "produce": ["raw", "washed", "peeled", "trimmed", "halved", "quartered", "wedged", "sliced", "diced", "chopped", "minced", "julienned", "grated", "crushed", "mashed", "zested", "juiced", "mixed", "blended", "pureed", "pickled", "fermented", "sauteed", "stir_fried", "shallow_fried", "boiled", "blanched", "steamed", "braised", "baked", "roasted", "grilled", "smoked", "wilted", "garnished", "plated"],
    "seasoning": ["raw", "washed", "chopped", "minced", "crushed", "grated", "toasted", "mixed", "sprinkled", "garnished"],
    "protein": ["raw", "trimmed", "sliced", "diced", "minced", "mixed", "marinated", "breaded", "shallow_fried", "deep_fried", "seared", "boiled", "simmered", "poached", "steamed", "braised", "baked", "roasted", "grilled", "smoked", "browned", "fully_cooked", "tender", "juicy", "lightly_charred", "plated"],
    "dairy": ["raw", "sliced", "diced", "grated", "cracked", "whisked", "mixed", "melted", "whipped", "sauced", "drizzled", "set", "plated"],
    "grain": ["raw", "washed", "sifted", "boiled", "steamed", "stir_fried", "mixed", "toasted", "baked", "plated"],
    "dough": ["raw", "sifted", "mixed", "kneaded", "folded", "rolled", "shaped", "baked", "toasted", "golden", "plated"],
    "liquid": ["raw", "mixed", "blended", "pureed", "simmered", "reduced", "thickened", "sauced", "drizzled", "plated"],
    "dessert": ["raw", "sifted", "chopped", "grated", "melted", "mixed", "whisked", "blended", "pureed", "kneaded", "folded", "rolled", "shaped", "baked", "caramelized", "whipped", "set", "drizzled", "sprinkled", "garnished", "plated"],
}


def dish_names(flutter_path: Path) -> list[str]:
    if not flutter_path.exists(): return []
    body = flutter_path.read_text(encoding="utf-8")
    return sorted(set(re.findall(r"'([^']+)'", " ".join(re.findall(r"'dishes':\s*\[([^\]]*)\]", body, flags=re.S)))))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, default=Path("asset_loader/recipe_animation_asset_manifest.json"))
    parser.add_argument("--flutter-catalog", type=Path, default=Path("flutter_app/lib/data/kitchen_data.dart"))
    parser.add_argument("--out", type=Path, default=Path("asset_loader/recipe_animation_asset_manifest.v2.json"))
    args = parser.parse_args()
    base = json.loads(args.base.read_text(encoding="utf-8-sig"))
    base.update({"version": "2.0.0", "library": "kitchen-diary-complete-visual-contract"})
    base["styleGuide"].update({"masterSize": [1024, 1024], "safePadding": "8-12 percent", "anchorPolicy": "family-locked anchors and pivots; no frame-to-frame jumps", "stateCuePolicy": "communicate by cuts, texture, moisture, bubbles, crust, char and steam; never colour alone"})
    base["processingStates"] = [{"id": key, "label": key.replace("_", " ").title(), "descriptor": desc} for key, desc in STATES]
    base["stateProfiles"] = PROFILES
    base["ingredients"] = [{"id": slug(name), "label": name, "category": category, "defaultUnit": "pcs", "stateProfile": profile_for(category, name)} for category, names in INGREDIENTS.items() for name in words(names)]
    base["synonyms"] = {"chickpea": "chickpeas", "lentil": "lentils", "black_bean": "black_beans", "generic_pepper": "black_pepper", "generic_cheese": "cheese", "noodle": "noodles"}
    base["tools"] = [{"id": slug(name), "label": name, "category": "tool"} for name in words(TOOLS)]
    base["actions"] = [{"id": slug(name), "label": name, "stage": "finish" if name in {"Drizzle", "Sprinkle", "Garnish", "Plate"} else "cook" if name in {"Sauté", "Stir Fry", "Fry", "Deep Fry", "Sear", "Blanch", "Boil", "Simmer", "Poach", "Steam", "Braise", "Bake", "Roast", "Grill", "Smoke", "Toast", "Scramble", "Reduce"} else "prep", "sequence": ["start", "active", "midpoint", "complete"], "reducedMotion": "complete"} for name in words(ACTIONS)]
    base["mixtures"] = [{"id": slug(name), "label": name} for name in words(MIXTURES)]
    base["effects"] = [{"id": slug(name), "label": name} for name in words(EFFECTS)]
    base["characters"] = [{"id": slug(name), "label": name, "layer": "character"} for name in words(CHARACTERS)]
    base["fallbacks"] = [{"id": slug(name), "label": name, "generic": True, "uiLabel": f"Generic representation: {name}"} for name in words(FALLBACKS)]
    dishes = dish_names(args.flutter_catalog)
    base["dishHeroes"] = [{"id": slug(name), "label": name, "frames": ["hero", "prep", "cook", "garnish", "static"], "masterSize": [1024, 1024]} for name in dishes]
    base["generationContract"] = {"formats": {"master": "PNG 1024x1024", "animation": "transparent WebP", "reducedMotion": "static PNG"}, "layers": ["character", "tool", "food", "effects"], "selectionOnly": True, "customInputPolicy": "show the explicit generic fallback label; never substitute a named ingredient"}
    args.out.write_text(json.dumps(base, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {args.out} with {len(base['ingredients'])} ingredients, {len(dishes)} dish heroes, {len(base['actions'])} action sequences.")


if __name__ == "__main__": main()
