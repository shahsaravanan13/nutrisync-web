import os
import json
import traceback
import shutil
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordRequestForm
from dotenv import load_dotenv
from sqlalchemy.orm import Session
from datetime import timedelta

# Robust environment variable loading using absolute paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"), override=True)

# Import local modules
from models import RecipeRequest, RecipeResponse, ChatRequest, ChatResponse
from vector_db import VectorDB
from ai_service import GeminiService
from database import engine, get_db
import sql_models
import schemas
from auth import (
    get_password_hash,
    verify_password,
    create_access_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

# Create tables
sql_models.Base.metadata.create_all(bind=engine)

# Ensure uploads directory exists
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# -----------------------------------------------------------------------------
# Lifespan Management
# -----------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    api_key = os.getenv("GEMINI_API_KEY")
    key_peek = f"{api_key[:4]}...{api_key[-4:]}" if api_key else "NOT FOUND"
    print(f"Nutrisync API starting up... (Using API Key: {key_peek})")
    
    global vdb, gemini
    try:
        vdb = VectorDB()
        gemini = GeminiService()
        
        if vdb.collection.count() == 0:
            print("Populating initial recipe database...")
            vdb.add_recipes("./database/recipes.json")
        else:
            print(f"Database contains {vdb.collection.count()} recipes.")
            
        import seed_db
        seed_db.create_seed_data()
        
    except Exception as e:
        print(f"CRITICAL STARTUP ERROR: {e}")
        traceback.print_exc()

    yield
    # Shutdown logic
    print("Nutrisync API shutting down...")

app = FastAPI(
    title="Nutrisync API",
    description="Backend for Recipe Generation and Nutritional Analysis using Gemini 1.5 and RAG.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Global variables for services
vdb = None
gemini = None

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------

@app.get("/")
async def root():
    return {"message": "Welcome to Nutrisync API. Visit /docs for Swagger UI documentation."}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# --- Auth Endpoints ---

@app.post("/api/v1/auth/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(sql_models.User).filter(
        (sql_models.User.username == user.username) | (sql_models.User.email == user.email)
    ).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username or Email already registered")
    
    hashed_password = get_password_hash(user.password)
    new_user = sql_models.User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        bio=user.bio,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/api/v1/auth/login", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(sql_models.User).filter(sql_models.User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/v1/auth/me", response_model=schemas.UserResponse)
def read_users_me(current_user: sql_models.User = Depends(get_current_user)):
    return current_user

@app.post("/api/v1/auth/upload-avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: sql_models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    file_ext = file.filename.split(".")[-1]
    new_filename = f"user_{current_user.id}_avatar.{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, new_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    current_user.profile_picture = f"/uploads/{new_filename}"
    db.commit()
    
    return {"message": "Profile picture updated successfully", "url": current_user.profile_picture}


# --- Data Endpoints ---

@app.get("/api/v1/recipes", response_model=list[schemas.RecipeBase])
def get_recipes(skip: int = 0, limit: int = 50, search: str = None, db: Session = Depends(get_db)):
    query = db.query(sql_models.Recipe)
    if search:
        query = query.filter(sql_models.Recipe.title.ilike(f"%{search}%"))
    return query.offset(skip).limit(limit).all()

@app.get("/api/v1/recipes/{recipe_id}", response_model=schemas.RecipeDetail)
def get_recipe(recipe_id: int, db: Session = Depends(get_db)):
    recipe = db.query(sql_models.Recipe).filter(sql_models.Recipe.id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    # Parse JSON strings to dicts before returning
    recipe_dict = {c.name: getattr(recipe, c.name) for c in recipe.__table__.columns}
    recipe_dict["ingredients"] = json.loads(recipe.ingredients)
    recipe_dict["instructions"] = json.loads(recipe.instructions)
    return recipe_dict

@app.get("/api/v1/ingredients", response_model=list[schemas.IngredientBase])
def get_ingredients(skip: int = 0, limit: int = 50, search: str = None, category: str = None, db: Session = Depends(get_db)):
    query = db.query(sql_models.IngredientDB)
    if search:
        query = query.filter(sql_models.IngredientDB.name.ilike(f"%{search}%"))
    if category:
        query = query.filter(sql_models.IngredientDB.category == category)
    return query.offset(skip).limit(limit).all()

@app.get("/api/v1/ingredients/{ingredient_id}", response_model=schemas.IngredientDetail)
def get_ingredient(ingredient_id: int, db: Session = Depends(get_db)):
    ingredient = db.query(sql_models.IngredientDB).filter(sql_models.IngredientDB.id == ingredient_id).first()
    if not ingredient:
        raise HTTPException(status_code=404, detail="Ingredient not found")
    
    ing_dict = {c.name: getattr(ingredient, c.name) for c in ingredient.__table__.columns}
    if ingredient.nutrition:
        ing_dict["nutrition"] = json.loads(ingredient.nutrition)
    return ing_dict

# --- AI Endpoints ---

@app.post("/api/v1/generate-recipe", response_model=RecipeResponse)
async def generate_recipe(request: RecipeRequest):
    if vdb is None or gemini is None:
        raise HTTPException(status_code=503, detail="Services not initialized")
        
    try:
        print(f"--- Generating recipe for: {request.ingredients} ---")
        
        # 1. Query the VectorDB for context
        query_text = f"Recipe with {', '.join(request.ingredients)}"
        search_results = vdb.query_recipes(query_text, n_results=2)
        
        # Prepare context for the AI
        context_recipes = []
        if search_results and "metadatas" in search_results and search_results["metadatas"]:
            for meta in search_results["metadatas"][0]:
                if "nutrition" in meta and isinstance(meta["nutrition"], str):
                    meta["nutrition"] = json.loads(meta["nutrition"])
                context_recipes.append(meta)

        # 2. Generate the recipe using Gemini
        recipe_response = gemini.generate_recipe(request, context_recipes)
        
        # 3. Generate the image URL (Synchronous as requested)
        print(f"Generating image for: {recipe_response.recipe_name}")
        image_url = gemini.get_image_url(recipe_response.recipe_name, request.ingredients)
        recipe_response.image_url = image_url
        
        print(f"Successfully generated: {recipe_response.recipe_name}")
        return recipe_response

    except Exception as e:
        print("!!! ERROR GENERATING RECIPE !!!")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/chat", response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest):
    if gemini is None:
        raise HTTPException(status_code=503, detail="Services not initialized")
    
    try:
        response_text = gemini.chat(request.message, request.history)
        return ChatResponse(response=response_text)
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    # Railway injects PORT via environment variable
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
