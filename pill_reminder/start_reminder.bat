@echo off
title Pill Reminder - Monty Python Edition
echo.
echo ============================================================
echo  Pill Reminder - Monty Python Edition
echo  Reminders loaded from config.json
echo  Agent API: http://localhost:5000
echo  Tray icon in system tray — right-click for Settings
echo ============================================================
echo.

:: Must run as admin for keyboard hook to work system-wide
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting admin rights for global keyboard listener...
    powershell -Command "Start-Process cmd -ArgumentList '/c cd /d ""%~dp0"" && python launcher.py' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

cd /d "%~dp0"
pip install -r requirements.txt --quiet
:: pythonw = no console window; tray icon is the only UI
pythonw launcher.py
