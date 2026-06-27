using System.Runtime.InteropServices;
using PillReminder;

// ── Hide the console window immediately ───────────────────────────────────────
[DllImport("kernel32.dll")] static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   static extern bool   ShowWindow(IntPtr hWnd, int nCmdShow);

var hwnd = GetConsoleWindow();
if (hwnd != IntPtr.Zero) ShowWindow(hwnd, 0); // SW_HIDE = 0

// ── Single-instance mutex ─────────────────────────────────────────────────────
using var mutex = new Mutex(true, "Global\\PillReminderMontyPython", out bool acquired);
if (!acquired)
{
    // Another instance is already running — exit silently
    return;
}

Log.Info("=== Pill Reminder (Monty Python Edition) starting ===");
Log.Info($"Config: {Config.ConfigPath}");

// ── Wire up services ──────────────────────────────────────────────────────────
var cts     = new CancellationTokenSource();
var voice   = new VoiceManager();
var reminder = new ReminderService(voice);
var api     = new HttpApi(reminder);

// Graceful shutdown on Ctrl+C (won't normally fire when hidden, but handy for debugging)
Console.CancelKeyPress += (_, e) =>
{
    e.Cancel = true;
    Log.Info("Shutdown requested.");
    cts.Cancel();
};

// Startup announcement
var cfg = Config.Load();
voice.Speak(
    $"Good news, brave knight! Your pill reminder system is now fully operational! " +
    $"The Black Knight of {cfg.Malady} shall not pass! " +
    $"I am... not dead yet!");

Log.Info($"Pill times: {string.Join(", ", cfg.PillTimes)}");

// ── Run until cancelled ───────────────────────────────────────────────────────
await Task.WhenAll(
    reminder.RunAsync(cts.Token),
    api.RunAsync(cts.Token)
);

Log.Info("Pill Reminder stopped.");
