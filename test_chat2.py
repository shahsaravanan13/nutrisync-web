import os, sys
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.abspath('backend'), ".env"), override=True)
sys.path.insert(0, os.path.abspath('backend'))
from ai_service import GeminiService
g = GeminiService()
r = g.chat("What are some high protein breakfast ideas?", [])
print("RESPONSE:", r[:200] if r else "NONE")
