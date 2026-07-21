import os
import json
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import sql_models
import random

def create_seed_data():
    sql_models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    if db.query(sql_models.Recipe).count() > 0:
        print("Database already seeded.")
        db.close()
        return

    print("Seeding database with 100+ recipes and ingredients...")
    
    # 1. Seed Ingredients
    ingredient_categories = [
        "Vegetables", "Fruits", "Herbs", "Spices", "Dairy", 
        "Meat", "Seafood", "Eggs", "Rice", "Pasta", 
        "Flour", "Bread", "Beans", "Lentils", "Nuts", 
        "Seeds", "Oils", "Sauces"
    ]
    
    ingredients_data = []
    for i in range(1, 101):
        cat = random.choice(ingredient_categories)
        nutrition = {
            "calories": random.randint(10, 500),
            "protein": random.randint(0, 50),
            "carbs": random.randint(0, 100),
            "fat": random.randint(0, 50)
        }
        ing = sql_models.IngredientDB(
            name=f"Mock Ingredient {i}",
            image_url=f"https://source.unsplash.com/150x150/?{cat.lower()}",
            category=cat,
            description=f"This is a description for Mock Ingredient {i}.",
            nutrition=json.dumps(nutrition)
        )
        ingredients_data.append(ing)
        
    db.add_all(ingredients_data)
    
    # 2. Seed Recipes
    cuisines = ["Indian", "Chinese", "Italian", "Mexican", "Thai", "Japanese", "Mediterranean", "American"]
    categories = ["Breakfast", "Lunch", "Dinner", "Snacks", "Desserts", "Healthy Meals", "Vegan"]
    difficulties = ["Easy", "Medium", "Hard"]
    
    recipes_data = []
    for i in range(1, 201):
        cuisine = random.choice(cuisines)
        category = random.choice(categories)
        
        ingredients_list = [{"name": f"Ingredient {j}", "quantity": f"{j}00g"} for j in range(1, 6)]
        instructions_list = [f"Step {j}: Do something with the ingredients." for j in range(1, 5)]
        
        recipe = sql_models.Recipe(
            title=f"Delicious {cuisine} {category} {i}",
            image_url=f"https://source.unsplash.com/400x300/?{cuisine.lower()},food",
            description=f"A wonderful {cuisine} dish perfect for {category}.",
            ingredients=json.dumps(ingredients_list),
            instructions=json.dumps(instructions_list),
            prep_time=random.randint(5, 30),
            cook_time=random.randint(10, 120),
            difficulty=random.choice(difficulties),
            servings=random.randint(1, 6),
            cuisine=cuisine,
            category=category,
            calories=random.randint(200, 1200),
            author="Chef NutriSync",
            rating=round(random.uniform(3.5, 5.0), 1)
        )
        recipes_data.append(recipe)
        
    db.add_all(recipes_data)
    db.commit()
    db.close()
    print("Seeding complete!")

if __name__ == "__main__":
    create_seed_data()
