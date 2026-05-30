from groq import Groq
import os
import json
import time
import urllib.parse
from dotenv import load_dotenv
from models import RecipeResponse, RecipeRequest, Nutrition, Ingredient as ModelIngredient
from typing import List, Dict
from nutrition_calculator import calculate_nutrition

# Force override
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"), override=True)

HISTORY_FILE = os.path.join(BASE_DIR, "recipe_history.json")

class GeminiService:
    def __init__(self):
        self.client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self.model_name = os.getenv("MODEL_NAME", "llama-3.3-70b-versatile")

    def _get_history(self) -> List[str]:
        if os.path.exists(HISTORY_FILE):
            try:
                with open(HISTORY_FILE, "r") as f:
                    history = json.load(f)
                    if isinstance(history, list):
                        return history
            except Exception as e:
                print(f"Error reading history file: {e}")
        return []

    def _save_history(self, recipe_name: str):
        history = self._get_history()
        # Avoid exact duplicates in history
        if recipe_name not in history:
            history.append(recipe_name)
        # Keep prompt size reasonable
        history = history[-30:]
        try:
            with open(HISTORY_FILE, "w") as f:
                json.dump(history, f, indent=2)
        except Exception as e:
            print(f"Error writing history file: {e}")

    def generate_recipe(self, request: RecipeRequest, context_recipes: List[Dict]) -> RecipeResponse:
        ingredients_str = ", ".join(request.ingredients)
        context_str = json.dumps(context_recipes, indent=2)
        
        # 1. Calculate precise nutrition values mathematically
        calc_result = calculate_nutrition(request.ingredients)
        calculated_totals = calc_result["total"]

        # 2. Get previously generated recipes to avoid duplicates
        history = self._get_history()
        history_str = ", ".join([f'"{name}"' for name in history]) if history else "None"

        prompt = f"""You are a professional chef. Your task is to generate a recipe using the provided ingredients.

USER INGREDIENTS: {ingredients_str}
DIETARY PREFERENCES: {request.dietary_preferences if request.dietary_preferences else 'None'}

PREVIOUSLY GENERATED RECIPES (DO NOT REPEAT OR DUPICATE THESE DISHES):
{history_str}

INSTRUCTIONS:
1. Create a unique, tasty, authentic recipe using the provided ingredients.
2. The recipe name MUST be different from the previously generated recipes. Do not repeat recipe names or types.
3. Explain each step in VERY SIMPLE English.
4. Return ONLY valid JSON, no extra text or markdown codeblocks.

Return this EXACT JSON structure:
{{
    "recipe_name": "Name of dish",
    "total_time": 25,
    "ingredients_used": [
        {{"name": "Ingredient name", "quantity": "exact amount with unit"}}
    ],
    "steps": [
        {{"step_number": 1, "instruction": "Clear simple instruction"}}
    ]
}}

Reference Context:
{context_str}
"""

        preferred_models = [self.model_name, "llama3-70b-8192", "gemma2-9b-it"]
        last_error = None

        for model_name in preferred_models:
            try:
                response = self.client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a professional chef. You generate unique recipes and return only valid JSON."
                        },
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.7,
                    max_tokens=2048,
                )

                text = response.choices[0].message.content
                if not text:
                    continue

                json_start = text.find("{")
                json_end = text.rfind("}") + 1
                if json_start == -1:
                    continue
                recipe_data = json.loads(text[json_start:json_end])

                # Ensure recipe name is unique against history
                recipe_name = recipe_data.get("recipe_name", "Gourmet Dish").strip()
                if recipe_name in history:
                    # Modify name slightly to be unique if the LLM ignored instructions
                    recipe_name = f"Special {recipe_name}"
                    recipe_data["recipe_name"] = recipe_name

                # 3. Save the generated recipe name to history
                self._save_history(recipe_name)

                # 4. Strictly inject the mathematically calculated accurate nutrition facts
                recipe_data["nutrition_facts"] = {
                    "calories": calculated_totals["calories"],
                    "protein": calculated_totals["protein"],
                    "carbohydrates": calculated_totals["carbohydrates"],
                    "fat": calculated_totals["fat"],
                    "fiber": calculated_totals["fiber"]
                }

                # Construct and return validated response model
                return RecipeResponse(
                    recipe_name=recipe_data["recipe_name"],
                    total_time=recipe_data.get("total_time", 20),
                    ingredients_used=[
                        ModelIngredient(name=ing["name"], quantity=ing["quantity"])
                        for ing in recipe_data.get("ingredients_used", [])
                    ],
                    steps=recipe_data.get("steps", []),
                    nutrition_facts=Nutrition(**recipe_data["nutrition_facts"])
                )

            except Exception as e:
                last_error = e
                error_msg = str(e).lower()
                if "429" in error_msg or "rate_limit" in error_msg:
                    time.sleep(2)
                continue

        raise last_error if last_error else Exception("Failed to generate recipe.")

    def generate_image_prompt(self, recipe_name: str, ingredients: List[str]) -> str:
        ingredients_str = ", ".join(ingredients)
        prompt = f"Write ONE sentence describing a professional food photo of {recipe_name} with {ingredients_str}. Focus on colors, textures, and gourmet plating."

        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=100,
            )
            text = response.choices[0].message.content
            if text:
                return text.strip()
        except:
            pass

        return f"Professional food photography of {recipe_name}, featuring {ingredients_str}, gourmet plating, high resolution, soft cinematic lighting."

    def get_image_url(self, recipe_name: str, ingredients: List[str]) -> str:
        visual_prompt = self.generate_image_prompt(recipe_name, ingredients)

        clean_prompt = visual_prompt.replace('\n', ' ').replace('\r', ' ').strip()
        while '  ' in clean_prompt:
            clean_prompt = clean_prompt.replace('  ', ' ')

        encoded_prompt = urllib.parse.quote(clean_prompt)
        seed = int(time.time()) % 1000

        url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width=1024&height=1024&seed={seed}&model=flux&nologo=true&private=true"
        print(f"Generated Image URL: {url}")
        return url

gemini_service = GeminiService()
