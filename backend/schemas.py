from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Any
from datetime import datetime

# --- Auth Schemas ---
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    bio: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str] = None
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

# --- Recipe & Ingredient Schemas (for SQL DB) ---
class RecipeBase(BaseModel):
    id: int
    title: str
    image_url: Optional[str]
    description: Optional[str]
    prep_time: Optional[int]
    cook_time: Optional[int]
    difficulty: Optional[str]
    cuisine: Optional[str]
    category: Optional[str]
    calories: Optional[float]
    rating: Optional[float]

    class Config:
        from_attributes = True

class RecipeDetail(RecipeBase):
    ingredients: Any # JSON
    instructions: Any # JSON
    servings: Optional[int]
    author: Optional[str]

class IngredientBase(BaseModel):
    id: int
    name: str
    image_url: Optional[str]
    category: Optional[str]

    class Config:
        from_attributes = True

class IngredientDetail(IngredientBase):
    description: Optional[str]
    nutrition: Any # JSON
