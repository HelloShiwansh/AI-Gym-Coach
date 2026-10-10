@echo off
setlocal
cd /d "%~dp0Main App"
if not exist ".venv\Scripts\python.exe" (
    echo The project environment is missing. Follow Local Setup in README.md first.
    pause
    exit /b 1
)
".venv\Scripts\python.exe" -m streamlit run main.py --browser.gatherUsageStats false
