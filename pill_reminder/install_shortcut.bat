@echo off
:: Creates a Start Menu shortcut that launches Pill Reminder silently (no console window)
:: and adds it to Windows Startup so it runs automatically on login.

set SCRIPT_DIR=%~dp0
set PYTHONW=pythonw.exe
set TARGET=%SCRIPT_DIR%launcher.py
set START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

echo Creating Start Menu shortcut...
powershell -Command ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('%START_MENU%\Pill Reminder.lnk'); ^
   $s.TargetPath = '%PYTHONW%'; ^
   $s.Arguments = '\"%TARGET%\"'; ^
   $s.WorkingDirectory = '%SCRIPT_DIR%'; ^
   $s.Description = 'Pill Reminder - Monty Python Edition'; ^
   $s.IconLocation = 'shell32.dll,132'; ^
   $s.Save()"

echo Creating Startup shortcut (runs on login)...
powershell -Command ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('%STARTUP%\Pill Reminder.lnk'); ^
   $s.TargetPath = '%PYTHONW%'; ^
   $s.Arguments = '\"%TARGET%\"'; ^
   $s.WorkingDirectory = '%SCRIPT_DIR%'; ^
   $s.Description = 'Pill Reminder - Monty Python Edition'; ^
   $s.IconLocation = 'shell32.dll,132'; ^
   $s.Save()"

echo.
echo Done! Pill Reminder will now:
echo   - Appear in your Start Menu as "Pill Reminder"
echo   - Start automatically when you log into Windows
echo.
echo To remove from startup, delete:
echo   %STARTUP%\Pill Reminder.lnk
pause
