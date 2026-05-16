from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from groq import Groq
from dotenv import load_dotenv
import json
import os

load_dotenv()

app = FastAPI()
client = Groq(api_key=os.environ["GROQ_API_KEY"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    model: str = "llama-3.3-70b-versatile"


@app.post("/chat")
def chat(req: ChatRequest):
    def stream():
        completion = client.chat.completions.create(
            model=req.model,
            messages=[m.model_dump() for m in req.messages],
            stream=True,
        )
        for chunk in completion:
            delta = chunk.choices[0].delta.content
            if delta:
                yield f"data: {json.dumps({'text': delta})}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(stream(), media_type="text/event-stream")


@app.get("/models")
def list_models():
    return {
        "models": [
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
            "mixtral-8x7b-32768",
            "gemma2-9b-it",
        ]
    }
