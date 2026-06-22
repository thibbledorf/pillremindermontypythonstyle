# Install Windows Task Scheduler wake timers for Pill Reminder
# Runs as admin. Creates tasks that wake the system at reminder times and trigger the app.
# Usage: powershell -ExecutionPolicy Bypass -File install_wake_timers.ps1

param(
    [string]$LauncherPath = ""
)

# Detect launcher path if not provided
if (-not $LauncherPath) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $LauncherPath = Join-Path $ScriptDir "launcher.py"
}

if (-not (Test-Path $LauncherPath)) {
    Write-Host "Error: launcher.py not found at $LauncherPath" -ForegroundColor Red
    exit 1
}

$PythonExe = (Get-Command python.exe -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = (Get-Command pythonw.exe -ErrorAction SilentlyContinue).Source
}
if (-not $PythonExe) {
    Write-Host "Error: Python not found. Install Python or add it to PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Using Python: $PythonExe" -ForegroundColor Green
Write-Host "Launcher: $LauncherPath" -ForegroundColor Green
Write-Host ""

# Read config.json to get reminder times
$ConfigFile = Join-Path (Split-Path -Parent $LauncherPath) "config.json"
$PillTimes = @("07:00", "13:00", "17:00", "21:00")  # defaults

if (Test-Path $ConfigFile) {
    try {
        $Config = Get-Content $ConfigFile | ConvertFrom-Json
        if ($Config.pill_times) {
            $PillTimes = $Config.pill_times
        }
    } catch {
        Write-Host "Could not read config.json, using defaults: $($PillTimes -join ', ')" -ForegroundColor Yellow
    }
}

Write-Host "Creating scheduled tasks for reminder times: $($PillTimes -join ', ')" -ForegroundColor Cyan
Write-Host ""

# Create an action that calls launcher.py (which will trigger the reminder via API)
# We use a trigger endpoint so the reminder fires immediately when the system wakes
$TaskAction = New-ScheduledTaskAction `
    -Execute $PythonExe `
    -Argument "-c `"import requests; requests.post('http://localhost:5000/trigger', timeout=3)`""

# For each reminder time, create a scheduled task
foreach ($Time in $PillTimes) {
    $Hour, $Minute = $Time.Split(":")
    $TaskName = "Pill Reminder - $Time"

    # Remove existing task if it exists
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Removed existing task: $TaskName"
    } catch {}

    # Create daily trigger at the specified time
    $Trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At "$($Hour):$($Minute)"

    # Create the scheduled task
    try {
        $Task = Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $TaskAction `
            -Trigger $Trigger `
            -RunLevel Highest `
            -ErrorAction Stop

        # Enable "Wake the computer to run this task"
        # Access the task definition and set the WakeToRun flag
        $TaskService = New-Object -ComObject Schedule.Service
        $TaskService.Connect()
        $RootFolder = $TaskService.GetFolder("\")
        $TaskDef = $RootFolder.GetTask($TaskName).Definition
        $TaskDef.Settings.WakeToRun = $true
        $RootFolder.RegisterTaskDefinition($TaskName, $TaskDef, 4, $null, $null, 3) | Out-Null

        Write-Host "✓ Created task: $TaskName (Wake: enabled)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to create task $TaskName : $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done! Your pill reminders will now wake the system from sleep." -ForegroundColor Green
Write-Host ""
Write-Host "To view or edit tasks, open Task Scheduler (taskschd.msc) and look for 'Pill Reminder' tasks." -ForegroundColor Cyan
Write-Host "To remove tasks later, run: Get-ScheduledTask -TaskName 'Pill Reminder*' | Unregister-ScheduledTask -Confirm:0" -ForegroundColor Gray
