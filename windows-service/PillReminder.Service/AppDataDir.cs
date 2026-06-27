namespace PillReminder;

public static class AppDataDir
{
    public static readonly string Path = Init();

    private static string Init()
    {
        var dir = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "PillReminder");
        Directory.CreateDirectory(dir);
        return dir;
    }
}
