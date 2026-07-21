from sqlalchemy import Column, Integer, String, Text, DateTime, Float, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    profile_picture = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    image_url = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    ingredients = Column(Text, nullable=False) # Store as JSON string
    instructions = Column(Text, nullable=False) # Store as JSON string
    prep_time = Column(Integer, nullable=True)
    cook_time = Column(Integer, nullable=True)
    difficulty = Column(String, nullable=True)
    servings = Column(Integer, nullable=True)
    cuisine = Column(String, index=True, nullable=True)
    category = Column(String, index=True, nullable=True)
    calories = Column(Float, nullable=True)
    author = Column(String, nullable=True)
    rating = Column(Float, nullable=True)

class IngredientDB(Base):
    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    image_url = Column(String, nullable=True)
    category = Column(String, index=True, nullable=True)
    description = Column(Text, nullable=True)
    nutrition = Column(Text, nullable=True) # JSON string
