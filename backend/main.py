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

# ── MOCK DATA ──────────────────────────────────────────────
MOCK_DATA = {
    "motorista_teste_001": {
        "alunos": [
            {"nome": "Ana Silva",    "contrato_ativo": True},
            {"nome": "Bruno Costa",  "contrato_ativo": True},
            {"nome": "Carla Mendes", "contrato_ativo": True},
            {"nome": "Diego Souza",  "contrato_ativo": False},
            {"nome": "Elena Rocha",  "contrato_ativo": True},
        ],
        "presencas": [
            {"aluno": "Ana Silva",    "data": "2026-04-28", "presente": True},
            {"aluno": "Bruno Costa",  "data": "2026-04-28", "presente": True},
            {"aluno": "Carla Mendes", "data": "2026-04-28", "presente": False},
            {"aluno": "Diego Souza",  "data": "2026-04-28", "presente": True},
            {"aluno": "Elena Rocha",  "data": "2026-04-28", "presente": True},
            {"aluno": "Ana Silva",    "data": "2026-04-29", "presente": True},
            {"aluno": "Bruno Costa",  "data": "2026-04-29", "presente": False},
            {"aluno": "Carla Mendes", "data": "2026-04-29", "presente": True},
            {"aluno": "Diego Souza",  "data": "2026-04-29", "presente": False},
            {"aluno": "Elena Rocha",  "data": "2026-04-29", "presente": True},
        ],
        "financeiro": [
            {"aluno": "Ana Silva",    "valor": 350.00, "status": "pago",     "vencimento": "2026-04-10"},
            {"aluno": "Bruno Costa",  "valor": 350.00, "status": "pendente", "vencimento": "2026-04-10"},
            {"aluno": "Carla Mendes", "valor": 350.00, "status": "pendente", "vencimento": "2026-04-10"},
            {"aluno": "Diego Souza",  "valor": 350.00, "status": "pago",     "vencimento": "2026-04-10"},
            {"aluno": "Elena Rocha",  "valor": 350.00, "status": "pendente", "vencimento": "2026-04-10"},
        ],
    }
}

def buscar_contexto(motorista_id: str) -> str:
    dados = MOCK_DATA.get(motorista_id)

    if not dados:
        return "Nenhum dado encontrado para este motorista."    

    alunos = dados["alunos"]
    presencas = dados["presencas"]
    financeiro = dados["financeiro"]

    nomes = ", ".join([a["nome"] for a in alunos])
    contratos_ativos = sum(1 for a in alunos if a["contrato_ativo"])

    presentes = sum(1 for p in presencas if p["presente"])
    ausentes = len(presencas) - presentes

    a_receber = sum(f["valor"] for f in financeiro if f["status"] == "pendente")
    inadimplentes = [f["aluno"] for f in financeiro if f["status"] == "pendente"]

    return f"""
Alunos cadastrados ({len(alunos)}): {nomes}
Contratos ativos: {contratos_ativos}
Presenças recentes ({len(presencas)} registros): {presentes} presentes, {ausentes} ausentes
Valores a receber: R$ {a_receber:.2f}
Alunos com pagamento pendente: {", ".join(inadimplentes)}
""".strip()
# ── FIM MOCK ───────────────────────────────────────────────


class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    motorista_id: str = "motorista_teste_001"
    model: str = "llama-3.3-70b-versatile"


@app.post("/chat")
def chat(req: ChatRequest):
    contexto = buscar_contexto(req.motorista_id)

    system_prompt = f"""Você é um assistente inteligente do aplicativo Niccioli,
voltado para motoristas de transporte fretado universitário.

Dados atuais do sistema:
{contexto}

Responda perguntas, gere resumos e oriente o motorista de forma clara e objetiva.
Responda sempre em português.
Sempre priorize respostas diretas, sem contornar muito, quero algo bem organizado e direto ao ponto
"""

    mensagens = [{"role": "system", "content": system_prompt}] + \
                [m.model_dump() for m in req.messages]

    def stream():
        completion = client.chat.completions.create(
            model=req.model,
            messages=mensagens,
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