using System.Text.Json;
using System.Text.Json.Serialization;

namespace PillReminder;

public class Config
{
    [JsonPropertyName("pill_times")]
    public string[] PillTimes { get; set; } = ["07:00", "13:00", "17:00", "21:00"];

    [JsonPropertyName("malady")]
    public string Malady { get; set; } = "Parkinson's";

    [JsonPropertyName("voice_gender")]
    public string VoiceGender { get; set; } = "male";

    [JsonPropertyName("voice_accent")]
    public string VoiceAccent { get; set; } = "british";

    [JsonPropertyName("location")]
    public string Location { get; set; } = "";

    public static readonly string ConfigPath = Path.Combine(AppDataDir.Path, "config.json");

    private static readonly JsonSerializerOptions _opts = new() { WriteIndented = true };

    public static Config Load()
    {
        try
        {
            if (File.Exists(ConfigPath))
                return JsonSerializer.Deserialize<Config>(File.ReadAllText(ConfigPath)) ?? new Config();
        }
        catch (Exception ex) { Log.Warn($"Config load failed: {ex.Message}"); }
        return new Config();
    }

    public void Save()
    {
        try { File.WriteAllText(ConfigPath, JsonSerializer.Serialize(this, _opts)); }
        catch (Exception ex) { Log.Warn($"Config save failed: {ex.Message}"); }
    }
}
