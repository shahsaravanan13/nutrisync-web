import os
import json
import time
import urllib.parse
from dotenv import load_dotenv
from models import RecipeResponse, RecipeRequest, NutritionFacts, Ingredient as ModelIngredient, RecipeStep
from typing import List, Dict
from google import genai
from google.genai import types

# Force override
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"), override=True)

HISTORY_FILE = os.path.join(BASE_DIR, "recipe_history.json")

class GeminiService:
    def __init__(self):
        # Use GEMINI_API_KEY for the official SDK
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY is missing from environment variables.")
        self.client = genai.Client(api_key=api_key)
        # Use gemini-1.5-flash as the default robust model
        self.model_name = "gemini-1.5-flash"

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
        
        history = self._get_history()
        history_str = ", ".join([f'"{name}"' for name in history]) if history else "None"

        # Construct highly specific prompt
        prompt = f"""You are an elite nutritionist and professional chef. Your task is to generate a recipe using the provided ingredients, and ACCURATELY calculate its total nutrition facts based on reliable food databases (like USDA).

USER INGREDIENTS: {ingredients_str}
DIETARY PREFERENCES: {request.dietary_preferences if request.dietary_preferences else 'None'}

PREVIOUSLY GENERATED RECIPES (DO NOT REPEAT THESE):
{history_str}

INSTRUCTIONS:
1. Create a unique, tasty recipe using the provided ingredients. Do not repeat recipe names from history.
2. Carefully estimate the EXACT gram amount or serving size for every ingredient you use in the recipe.
3. Calculate the highly accurate TOTAL calories, protein (g), carbohydrates (g), fat (g), and fiber (g) for the entire dish. Do not hallucinate; use standard nutritional knowledge.
4. Explain each step in very simple English.

Return ONLY valid JSON matching this schema:
{{
    "recipe_name": "Name of dish",
    "total_time": 25,
    "ingredients_used": [
        {{"name": "Ingredient name", "quantity": "exact amount with unit"}}
    ],
    "steps": [
        {{"step_number": 1, "instruction": "Clear simple instruction"}}
    ],
    "nutrition_facts": {{
        "calories": 450,
        "protein": 30,
        "carbohydrates": 45,
        "fat": 15,
        "fiber": 8
    }}
}}
"""

        try:
            # Force JSON response schema via config
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    response_mime_type="application/json",
                ),
            )

            text = response.text
            recipe_data = json.loads(text)

            recipe_name = recipe_data.get("recipe_name", "Gourmet Dish").strip()
            if recipe_name in history:
                recipe_name = f"Special {recipe_name}"
                recipe_data["recipe_name"] = recipe_name

            self._save_history(recipe_name)

            # Ensure nutrition facts exists
            n_facts = recipe_data.get("nutrition_facts", {})

            return RecipeResponse(
                recipe_name=recipe_data["recipe_name"],
                total_time=recipe_data.get("total_time", 20),
                ingredients_used=[
                    ModelIngredient(name=ing.get("name", "Unknown"), quantity=ing.get("quantity", ""))
                    for ing in recipe_data.get("ingredients_used", [])
                ],
                steps=[
                    RecipeStep(step_number=step.get("step_number", idx+1), instruction=step.get("instruction", ""))
                    for idx, step in enumerate(recipe_data.get("steps", []))
                ],
                nutrition_facts=NutritionFacts(
                    calories=float(n_facts.get("calories", 0)),
                    protein=float(n_facts.get("protein", 0)),
                    carbohydrates=float(n_facts.get("carbohydrates", 0)),
                    fat=float(n_facts.get("fat", 0)),
                    fiber=float(n_facts.get("fiber", 0))
                )
            )

        except Exception as e:
            raise Exception(f"Failed to generate recipe via Gemini: {str(e)}")

    def generate_image_prompt(self, recipe_name: str, ingredients: List[str]) -> str:
        ingredients_str = ", ".join(ingredients)
        prompt = f"Write ONE sentence describing a professional food photo of {recipe_name} with {ingredients_str}. Focus on colors, textures, and gourmet plating."

        try:
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.7),
            )
            if response.text:
                return response.text.strip()
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
        return url

    def chat(self, user_message: str, history: List[Dict[str, str]] = None) -> str:
        # Build contents from history
        contents = []
        
        system_instruction = "You are NutriBot, a helpful, encouraging, and expert AI nutritionist and chef. You give concise, actionable advice about healthy eating, meal prep, and nutrition. Format your answers clearly with bullet points if helpful, but NO heavy markdown."
        
        # In python google-genai, we can use system_instruction in config
        if history:
            for msg in history[-10:]:
                role = "user" if msg["role"] == "user" else "model"
                contents.append(types.Content(role=role, parts=[types.Part.from_text(text=msg["content"])]))
                
        contents.append(types.Content(role="user", parts=[types.Part.from_text(text=user_message)]))

        try:
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    system_instruction=system_instruction
                )
            )
            return response.text
        except Exception as e:
            return f"I'm sorry, I encountered an error: {str(e)}"

gemini_service = GeminiService()
