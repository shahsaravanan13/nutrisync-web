import google.generativeai as genai
import os
from dotenv import load_dotenv
load_dotenv(".env")
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
res = genai.embed_content(model="models/text-embedding-004", content=["hello", "world"])
print(type(res['embedding']))
print(type(res['embedding'][0]))
