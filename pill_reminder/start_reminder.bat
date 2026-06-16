@echo off
title Pill Reminder - Monty Python Edition
echo.
echo ============================================================
echo  Pill Reminder - Monty Python Edition
echo  Reminders: 07:00  13:00  17:00  21:00
echo  Agent API: http://localhost:5000
echo  Press Ctrl+C to stop
echo ============================================================
echo.

:: Must run as admin for keyboard hook to work system-wide
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting admin rights for global keyboard listener...
    powershell -Command "Start-Process cmd -ArgumentList '/c cd /d ""%~dp0"" && python pill_reminder.py' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
python pill_reminder.py
pause
