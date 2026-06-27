#Requires -RunAsAdministrator
$TaskName = "PillReminderMontyPython"

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Stop-ScheduledTask  -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task '$TaskName' removed." -ForegroundColor Green
} else {
    Write-Host "Task '$TaskName' not found — nothing to remove." -ForegroundColor Yellow
}
