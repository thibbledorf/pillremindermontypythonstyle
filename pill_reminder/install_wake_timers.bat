@echo off
:: Install Windows Task Scheduler wake timers for Pill Reminder
:: Requires admin rights. Will prompt for elevation if needed.

setlocal enabledelayedexpansion

:: Check if running as admin
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting admin rights...
    powershell -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0install_wake_timers.ps1\"' -Verb RunAs"
    exit /b
)

:: Run the PowerShell script as admin
powershell -ExecutionPolicy Bypass -File "%~dp0install_wake_timers.ps1"
pause
