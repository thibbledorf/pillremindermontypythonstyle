using System.Diagnostics;
using System.Text.Json;

namespace PillReminder;

/// <summary>
/// Tracks consecutive crashes and shows a notification if crashes are frequent.
/// Crash counter stored in AppData with timestamps.
/// </summary>
static class CrashDetector
{
    private static readonly string CrashLogPath =
        Path.Combine(AppDataDir.Path, "crash_log.json");

    private static readonly string PillReminderLogPath =
        Path.Combine(AppDataDir.Path, "pill_reminder.log");

    private const int CrashThreshold = 3;           // Alert if N crashes
    private const int CrashTimeWindowMinutes = 10;  // ...within this many minutes

    record CrashRecord(DateTime Timestamp);

    public static void RecordCrash()
    {
        var crashes = LoadCrashes();
        crashes.Add(new CrashRecord(DateTime.UtcNow));

        // Keep only recent crashes
        var cutoff = DateTime.UtcNow.AddMinutes(-CrashTimeWindowMinutes);
        crashes = crashes.Where(c => c.Timestamp > cutoff).ToList();

        // Alert if too many recent crashes
        if (crashes.Count >= CrashThreshold)
        {
            ShowCrashAlert(crashes.Count, CrashTimeWindowMinutes);
        }

        SaveCrashes(crashes);
    }

    public static void ClearCrashes()
    {
        try
        {
            File.Delete(CrashLogPath);
        }
        catch { }
    }

    private static List<CrashRecord> LoadCrashes()
    {
        try
        {
            if (File.Exists(CrashLogPath))
            {
                var json = File.ReadAllText(CrashLogPath);
                return JsonSerializer.Deserialize<List<CrashRecord>>(json) ?? [];
            }
        }
        catch { }
        return [];
    }

    private static void SaveCrashes(List<CrashRecord> crashes)
    {
        try
        {
            var json = JsonSerializer.Serialize(crashes, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(CrashLogPath, json);
        }
        catch { }
    }

    private static void ShowCrashAlert(int count, int minutes)
    {
        Log.Error($"ALERT: {count} crashes in the last {minutes} minutes!");

        // Try to show a Windows toast notification
        try
        {
            ShowWindowsToastNotification(count, minutes);
        }
        catch (Exception ex)
        {
            Log.Warn($"Could not show toast: {ex.Message}");
            // Fallback: use msg.exe (visible system message)
            try
            {
                ShowMsgBoxAlert(count, minutes);
            }
            catch { }
        }
    }

    private static void ShowWindowsToastNotification(int count, int minutes)
    {
        // Use PowerShell to show a toast notification (works for interactive user sessions)
        var title = "⚠️ Pill Reminder Crashed";
        var message = $"The reminder service has crashed {count} times in the last {minutes} minutes.\n\n" +
                      $"Check logs at: {PillReminderLogPath}";

        var psScript = $@"
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$APP_ID = 'PillReminderMontyPython'
$template = @""
<toast>
    <visual>
        <binding template='ToastText02'>
            <text id='1'>{title}</text>
            <text id='2'>{message}</text>
        </binding>
    </visual>
</toast>
""@

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID).Show($toast)
";

        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -Command \"{psScript.Replace("\"", "\\\"")}\"",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        using var proc = Process.Start(psi);
        proc?.WaitForExit(5000);  // 5 second timeout
    }

    private static void ShowMsgBoxAlert(int count, int minutes)
    {
        // Fallback: use msg.exe (built-in Windows alert, visible to the logged-in user)
        var message = $"ALERT: Pill Reminder crashed {count} times in {minutes} minutes.\\n\\nCheck the log at:\\n{PillReminderLogPath}";
        var psi = new ProcessStartInfo
        {
            FileName = "msg.exe",
            Arguments = $"{Environment.UserName} {message}",
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var proc = Process.Start(psi);
        proc?.WaitForExit(2000);
    }
}
