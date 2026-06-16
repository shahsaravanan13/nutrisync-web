import os
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.abspath('backend'), ".env"), override=True)
from google import genai
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
for m in client.models.list():
    print(m.name)
