"""
Nutrition Calculator — calculates exact macros from ingredient strings.
Values are per 100g / 100ml from USDA FoodData Central.
"""

import re
from typing import Dict, List, Tuple

# ── Nutrition database (per 100g or 100ml) ──────────────────────────────────
# Format: { alias: (calories, protein_g, carbs_g, fat_g, fiber_g) }
NUTRITION_DB: Dict[str, Tuple[float, float, float, float, float]] = {
    # Fruits
    "banana":           (89,  1.1, 23.0, 0.3, 2.6),
    "apple":            (52,  0.3, 14.0, 0.2, 2.4),
    "mango":            (60,  0.8, 15.0, 0.4, 1.6),
    "orange":           (47,  0.9, 12.0, 0.1, 2.4),
    "grapes":           (69,  0.7, 18.0, 0.2, 0.9),
    "strawberry":       (32,  0.7,  7.7, 0.3, 2.0),
    "pineapple":        (50,  0.5, 13.0, 0.1, 1.4),
    "watermelon":       (30,  0.6,  8.0, 0.2, 0.4),
    "papaya":           (43,  0.5, 11.0, 0.3, 1.7),
    "date":             (277, 1.8, 75.0, 0.2, 6.7),
    "dates":            (277, 1.8, 75.0, 0.2, 6.7),
    "avocado":          (160, 2.0,  9.0,14.7, 6.7),
    "coconut":          (354, 3.3, 15.2,33.5, 9.0),
    "lemon":            (29,  1.1,  9.3, 0.3, 2.8),

    # Vegetables
    "potato":           (77,  2.0, 17.0, 0.1, 2.2),
    "sweet potato":     (86,  1.6, 20.0, 0.1, 3.0),
    "onion":            (40,  1.1,  9.3, 0.1, 1.7),
    "garlic":           (149, 6.4, 33.0, 0.5, 2.1),
    "tomato":           (18,  0.9,  3.9, 0.2, 1.2),
    "carrot":           (41,  0.9,  9.6, 0.2, 2.8),
    "spinach":          (23,  2.9,  3.6, 0.4, 2.2),
    "broccoli":         (34,  2.8,  7.0, 0.4, 2.6),
    "cauliflower":      (25,  1.9,  5.0, 0.3, 2.0),
    "capsicum":         (31,  1.0,  6.0, 0.3, 2.1),
    "bell pepper":      (31,  1.0,  6.0, 0.3, 2.1),
    "cabbage":          (25,  1.3,  5.8, 0.1, 2.5),
    "cucumber":         (16,  0.7,  3.6, 0.1, 0.5),
    "peas":             (81,  5.4, 14.5, 0.4, 5.1),
    "corn":             (86,  3.3, 19.0, 1.4, 2.7),
    "mushroom":         (22,  3.1,  3.3, 0.3, 1.0),
    "eggplant":         (25,  1.0,  5.9, 0.2, 3.0),
    "ginger":           (80,  1.8, 18.0, 0.8, 2.0),

    # Grains & Bread
    "bread":            (265, 9.0, 49.0, 3.2, 2.7),
    "white bread":      (265, 9.0, 49.0, 3.2, 2.7),
    "brown bread":      (247, 8.9, 41.0, 3.5, 6.0),
    "rice":             (130, 2.7, 28.0, 0.3, 0.4),
    "white rice":       (130, 2.7, 28.0, 0.3, 0.4),
    "brown rice":       (111, 2.6, 23.0, 0.9, 1.8),
    "flour":            (364,10.0, 76.0, 1.0, 2.7),
    "wheat flour":      (364,10.0, 76.0, 1.0, 2.7),
    "oats":             (389,17.0, 66.0, 7.0,10.0),
    "pasta":            (131, 5.0, 25.0, 1.1, 1.8),
    "noodles":          (138, 4.5, 25.0, 2.1, 1.8),
    "roti":             (297, 9.0, 55.0, 4.5, 3.0),
    "chapati":          (297, 9.0, 55.0, 4.5, 3.0),
    "bread slice":      (265, 9.0, 49.0, 3.2, 2.7),

    # Proteins - Meat & Eggs
    "egg":              (155,13.0,  1.1,11.0, 0.0),
    "eggs":             (155,13.0,  1.1,11.0, 0.0),
    "chicken":          (165,31.0,  0.0, 3.6, 0.0),
    "chicken breast":   (165,31.0,  0.0, 3.6, 0.0),
    "mutton":           (294,25.0,  0.0,21.0, 0.0),
    "fish":             (136,20.0,  0.0, 6.0, 0.0),
    "salmon":           (208,20.0,  0.0,13.0, 0.0),
    "tuna":             (144,30.0,  0.0, 1.0, 0.0),
    "shrimp":           (99, 24.0,  0.9, 0.3, 0.0),
    "beef":             (250,26.0,  0.0,15.0, 0.0),

    # Legumes
    "lentils":          (116, 9.0, 20.0, 0.4, 7.9),
    "dal":              (116, 9.0, 20.0, 0.4, 7.9),
    "chickpeas":        (164, 8.9, 27.0, 2.6, 7.6),
    "chana":            (164, 8.9, 27.0, 2.6, 7.6),
    "black beans":      (132, 8.9, 24.0, 0.5, 8.7),
    "kidney beans":     (127, 8.7, 23.0, 0.5, 6.4),
    "tofu":             (76,  8.0,  1.9, 4.8, 0.3),
    "soybeans":         (173,16.6, 10.0, 9.0, 6.0),
    "peanuts":          (567,25.8, 16.1,49.2, 8.5),
    "peanut butter":    (588,25.0, 20.0,50.0, 6.0),

    # Dairy
    "milk":             (61,  3.2,  4.8, 3.3, 0.0),
    "whole milk":       (61,  3.2,  4.8, 3.3, 0.0),
    "skim milk":        (34,  3.4,  5.0, 0.1, 0.0),
    "butter":           (717, 0.9,  0.1,81.0, 0.0),
    "ghee":             (900, 0.0,  0.0,99.5, 0.0),
    "cheese":           (402,25.0,  1.3,33.0, 0.0),
    "cheddar":          (402,25.0,  1.3,33.0, 0.0),
    "yogurt":           (59,  3.5,  5.0, 3.3, 0.0),
    "curd":             (98,  3.5, 11.4, 4.3, 0.0),
    "cream":            (340, 2.1,  2.8,36.0, 0.0),
    "paneer":           (265,18.3,  1.2,20.8, 0.0),

    # Oils & Fats
    "oil":              (884, 0.0,  0.0,100., 0.0),
    "vegetable oil":    (884, 0.0,  0.0,100., 0.0),
    "olive oil":        (884, 0.0,  0.0,100., 0.0),
    "coconut oil":      (892, 0.0,  0.0,100., 0.0),

    # Nuts & Seeds
    "almonds":          (579,21.0, 22.0,49.0,12.5),
    "cashews":          (553,18.0, 30.0,44.0, 3.3),
    "walnuts":          (654,15.2, 14.0,65.2, 6.7),
    "sesame seeds":     (573,17.0, 23.0,50.0,11.8),
    "chia seeds":       (486,17.0, 42.0,31.0,34.4),
    "flaxseeds":        (534,18.0, 29.0,42.0,27.3),
    "sunflower seeds":  (584,21.0, 20.0,51.0, 8.6),

    # Sweeteners
    "sugar":            (387, 0.0,100.0, 0.0, 0.0),
    "honey":            (304, 0.3, 82.4, 0.0, 0.2),
    "jaggery":          (383, 0.4, 98.0, 0.1, 0.0),

    # Spices (negligible but tracked)
    "salt":             (0,   0.0,  0.0, 0.0, 0.0),
    "pepper":           (251, 10.0,64.0, 3.3,25.3),
    "turmeric":         (312, 9.7, 67.0, 3.2,22.7),
    "cumin":            (375,18.0, 44.0,22.0,10.5),
    "coriander":        (23,  2.1,  3.7, 0.5, 2.8),
}

# ── Unit conversion to grams ─────────────────────────────────────────────────
UNIT_TO_GRAMS: Dict[str, float] = {
    # Weight
    "g": 1.0, "gram": 1.0, "grams": 1.0,
    "kg": 1000.0, "kilogram": 1000.0,
    "mg": 0.001, "milligram": 0.001,
    "oz": 28.35, "ounce": 28.35, "ounces": 28.35,
    "lb": 453.6, "pound": 453.6,
    # Volume → approximate ml≈g for water-based foods
    "ml": 1.0, "milliliter": 1.0, "millilitre": 1.0,
    "l": 1000.0, "liter": 1000.0, "litre": 1000.0,
    "cup": 240.0, "cups": 240.0,
    "tbsp": 15.0, "tablespoon": 15.0, "tablespoons": 15.0,
    "tsp": 5.0, "teaspoon": 5.0, "teaspoons": 5.0,
    # Approximate counts (will be overridden per ingredient below)
    "piece": None, "pieces": None,
    "slice": None, "slices": None,
    "clove": None, "cloves": None,
}

# ── Approximate weight per unit for countable items ─────────────────────────
UNIT_WEIGHT_MAP: Dict[str, Dict[str, float]] = {
    "banana":       {"piece": 118, "medium": 118, "large": 136, "small": 90},
    "egg":          {"piece": 50, "large": 60, "medium": 50, "small": 40},
    "eggs":         {"piece": 50, "large": 60, "medium": 50, "small": 40},
    "bread":        {"slice": 30, "piece": 30},
    "bread slice":  {"slice": 30, "piece": 30},
    "date":         {"piece": 8,  "dates": 8},
    "dates":        {"piece": 8},
    "garlic":       {"clove": 5},
    "potato":       {"piece": 150, "medium": 150, "large": 250},
    "tomato":       {"piece": 120, "medium": 120},
    "onion":        {"piece": 100, "medium": 100},
    "apple":        {"piece": 182, "medium": 182},
    "orange":       {"piece": 131, "medium": 131},
    "lemon":        {"piece": 84},
}

def _match_ingredient(text: str) -> str | None:
    """Find the best matching key in NUTRITION_DB for ingredient text."""
    text_lower = text.lower().strip()
    # Exact match first
    if text_lower in NUTRITION_DB:
        return text_lower
    # Partial match
    for key in sorted(NUTRITION_DB.keys(), key=len, reverse=True):
        if key in text_lower:
            return key
    return None

def _parse_quantity(text: str) -> Tuple[float, str, str]:
    """
    Parse '2 bananas', '200ml milk', '1.5 cups oats' etc.
    Returns (amount, unit, ingredient_name)
    """
    text = text.strip().lower()
    # Pattern: optional number + optional unit + ingredient
    pattern = r'^(\d+\.?\d*)\s*([a-z]+)?\s*(.+)$'
    m = re.match(pattern, text)
    if not m:
        return 1.0, "piece", text

    amount = float(m.group(1))
    unit = (m.group(2) or "piece").strip()
    ingredient = m.group(3).strip()

    # Handle "2 medium bananas" style
    size_words = {"small", "medium", "large", "big", "whole", "fresh", "raw", "cooked", "dried"}
    if unit in size_words:
        # e.g. "2 medium bananas" → amount=2, size=medium, ingredient=bananas
        return amount, unit, ingredient

    if unit not in UNIT_TO_GRAMS and unit not in {"piece", "pieces", "slice", "slices", "clove", "cloves"}:
        # unit word is probably part of ingredient name
        ingredient = f"{unit} {ingredient}"
        unit = "piece"

    # Clean noise words from the beginning of the ingredient name
    ingredient = re.sub(r'^(of|and|with|about|approx|approximately)\s+', '', ingredient)
    return amount, unit, ingredient

def calculate_nutrition(ingredients: List[str]) -> Dict:
    """
    Calculate total nutrition for a list of ingredient strings.
    Returns dict with per-serving and total macros.
    """
    total = {"calories": 0.0, "protein": 0.0, "carbohydrates": 0.0, "fat": 0.0, "fiber": 0.0}
    breakdown = []

    for raw in ingredients:
        amount, unit, ing_name = _parse_quantity(raw)
        db_key = _match_ingredient(ing_name)

        if db_key is None:
            breakdown.append({"ingredient": raw, "note": "not found in database"})
            continue

        cal, prot, carb, fat, fib = NUTRITION_DB[db_key]

        # Determine weight in grams
        grams = None
        if unit in UNIT_TO_GRAMS and UNIT_TO_GRAMS[unit] is not None:
            grams = amount * UNIT_TO_GRAMS[unit]
        elif db_key in UNIT_WEIGHT_MAP:
            wmap = UNIT_WEIGHT_MAP[db_key]
            weight_per = wmap.get(unit) or wmap.get("piece", 100)
            grams = amount * weight_per
        else:
            # Default: 1 piece ≈ 100g
            grams = amount * 100

        factor = grams / 100.0
        item = {
            "ingredient": raw,
            "grams": round(grams, 1),
            "calories": round(cal * factor, 1),
            "protein":  round(prot * factor, 1),
            "carbs":    round(carb * factor, 1),
            "fat":      round(fat * factor, 1),
            "fiber":    round(fib * factor, 1),
        }
        breakdown.append(item)
        total["calories"]      += item["calories"]
        total["protein"]       += item["protein"]
        total["carbohydrates"] += item["carbs"]
        total["fat"]           += item["fat"]
        total["fiber"]         += item["fiber"]

    # Per serving (2 servings default)
    servings = 2
    per_serving = {k: round(v / servings) for k, v in total.items()}
    total_rounded = {k: round(v) for k, v in total.items()}

    return {
        "total": total_rounded,
        "per_serving": per_serving,
        "servings": servings,
        "breakdown": breakdown,
    }
