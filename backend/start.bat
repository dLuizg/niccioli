@echo off
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo Criando ambiente virtual...
    python -m venv .venv
)

call .venv\Scripts\activate.bat

pip install -r requirements.txt -q

echo.
echo Niccioli Backend rodando em http://localhost:8000
echo Pressione Ctrl+C para parar.
echo.

uvicorn main:app --host 0.0.0.0 --port 8000
