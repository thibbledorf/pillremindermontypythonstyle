#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$ScriptDir  = $PSScriptRoot
$ProjectDir = Join-Path $ScriptDir "PillReminder.Service"
$PublishDir = Join-Path $ProjectDir "bin\Release\net8.0-windows\win-x64\publish"
$ExePath    = Join-Path $PublishDir "PillReminder.exe"
$TaskName   = "PillReminderMontyPython"

# --- 1. Build ---
Write-Host "Building PillReminder..." -ForegroundColor Cyan
dotnet publish $ProjectDir -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
if (-not (Test-Path $ExePath)) {
    Write-Error "Build failed - exe not found at $ExePath"
    exit 1
}
Write-Host "Build succeeded: $ExePath" -ForegroundColor Green

# --- 2. Config ---
$ConfigDir = Join-Path $env:APPDATA "PillReminder"
$ConfigDst = Join-Path $ConfigDir "config.json"
$ConfigSrc = Join-Path $ScriptDir "..\pill_reminder\config.json"

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

if (-not (Test-Path $ConfigDst)) {
    if (Test-Path $ConfigSrc) {
        Copy-Item $ConfigSrc $ConfigDst
        Write-Host "Copied config from pill_reminder/config.json" -ForegroundColor Green
    } else {
        Set-Content -Path $ConfigDst -Encoding utf8 -Value '{"pill_times":["07:00","13:00","17:00","21:00"],"malady":"Parkinsons","voice_gender":"male","voice_accent":"british"}'
        Write-Host "Created default config at $ConfigDst" -ForegroundColor Yellow
    }
}

# --- 3. Register scheduled task ---
Write-Host "Registering scheduled task..." -ForegroundColor Cyan

$action   = New-ScheduledTaskAction -Execute $ExePath
$trigger  = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RestartCount 5 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Principal   $principal `
    -Description "Monty Python Pill Reminder - starts at logon, restarts on crash" `
    -Force | Out-Null

Write-Host "Task registered successfully." -ForegroundColor Green

# --- 4. Start now ---
Write-Host "Starting task now..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $TaskName

$LogPath = Join-Path $ConfigDir "pill_reminder.log"
Write-Host ""
Write-Host "Done! PillReminder is running." -ForegroundColor Green
Write-Host "  Config:  $ConfigDst"
Write-Host "  Log:     $LogPath"
Write-Host "  API:     http://127.0.0.1:5000/status"
Write-Host ""
Write-Host "To restart after settings change:"
Write-Host "  Stop-ScheduledTask  -TaskName $TaskName"
Write-Host "  Start-ScheduledTask -TaskName $TaskName"
