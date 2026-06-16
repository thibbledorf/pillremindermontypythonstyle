@echo off
title Pill Reminder - Installing Dependencies
echo.
echo ============================================================
echo  Pill Reminder - Monty Python Edition - Installing...
echo ============================================================
echo.

:: Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please install Python 3.10+ from python.org
    pause
    exit /b 1
)

echo [1/3] Upgrading pip...
python -m pip install --upgrade pip --quiet

echo [2/3] Installing dependencies...
pip install schedule pyttsx3 SpeechRecognition sounddevice numpy requests feedparser flask keyboard anthropic

echo [3/3] Verifying installation...
python -c "import schedule, pyttsx3, speech_recognition, sounddevice, numpy, requests, feedparser, flask, keyboard, anthropic; print('All modules OK!')"

echo.
echo ============================================================
echo  Installation complete! Run start_reminder.bat to launch.
echo ============================================================
pause
