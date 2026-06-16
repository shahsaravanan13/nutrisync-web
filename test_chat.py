import sys
import os
sys.path.append(os.path.abspath('backend'))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.abspath('backend'), ".env"), override=True)
from google import genai
from google.genai import types

api_key = os.getenv("GEMINI_API_KEY")
print("API Key present:", bool(api_key))
client = genai.Client(api_key=api_key)

try:
    response = client.models.generate_content(
        model=os.getenv("MODEL_NAME", "gemini-1.5-flash"),
        contents=["hey"],
        config=types.GenerateContentConfig(temperature=0.7)
    )
    print("Success:", response.text)
except Exception as e:
    import traceback
    traceback.print_exc()
