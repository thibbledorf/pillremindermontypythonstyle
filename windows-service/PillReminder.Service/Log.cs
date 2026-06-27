namespace PillReminder;

public static class Log
{
    private static readonly string _path = Path.Combine(AppDataDir.Path, "pill_reminder.log");
    private static readonly object _lock = new();

    public static void Info(string msg)  => Write("INFO ", msg);
    public static void Warn(string msg)  => Write("WARN ", msg);
    public static void Error(string msg) => Write("ERROR", msg);

    private static void Write(string level, string msg)
    {
        var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss}  {level}  {msg}";
        lock (_lock)
        {
            try { File.AppendAllText(_path, line + Environment.NewLine); } catch { }
        }
        Console.WriteLine(line);
    }
}
