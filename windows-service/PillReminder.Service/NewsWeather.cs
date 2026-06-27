using System.Net.Http.Json;
using System.Text.Json;
using System.Xml.Linq;

namespace PillReminder;

public static class NewsWeather
{
    private static readonly HttpClient _http = new() { Timeout = TimeSpan.FromSeconds(10) };

    private static readonly string[] _foxFeeds =
    [
        "https://moxie.foxnews.com/google-publisher/latest.xml",
        "http://feeds.foxnews.com/foxnews/latest",
    ];

    public static async Task<string> GetWeatherAsync()
    {
        try
        {
            // Use configured location first; fall back to IP lookup
            string location = Config.Load().Location.Trim().Replace(" ", "+");

            if (string.IsNullOrEmpty(location))
            {
                try
                {
                    var loc = await _http.GetFromJsonAsync<JsonElement>("https://ipinfo.io/json");
                    var city   = loc.TryGetProperty("city",   out var c) ? c.GetString() ?? "" : "";
                    var region = loc.TryGetProperty("region", out var r) ? r.GetString() ?? "" : "";
                    location = string.IsNullOrEmpty(city) ? "" : $"{city},{region}".Replace(" ", "+");
                }
                catch { }
            }

            var url = string.IsNullOrEmpty(location)
                ? "https://wttr.in/?format=j1"
                : $"https://wttr.in/{location}?format=j1";

            var data  = await _http.GetFromJsonAsync<JsonElement>(url);
            var cur   = data.GetProperty("current_condition")[0];
            var desc  = cur.GetProperty("weatherDesc")[0].GetProperty("value").GetString();
            var tempF = cur.GetProperty("temp_F").GetString();
            var feelF = cur.GetProperty("FeelsLikeF").GetString();
            var humid = cur.GetProperty("humidity").GetString();
            var area  = data.GetProperty("nearest_area")[0]
                            .GetProperty("areaName")[0]
                            .GetProperty("value").GetString() ?? location;

            return $"Weather in {area}: {desc}. Temperature {tempF} degrees Fahrenheit, " +
                   $"feels like {feelF}. Humidity {humid} percent.";
        }
        catch (Exception ex)
        {
            Log.Warn($"Weather fetch failed: {ex.Message}");
            return "The weather spirits are being most uncooperative today, " +
                   "much like those dreadful French knights.";
        }
    }

    public static async Task<List<string>> GetFoxHeadlinesAsync()
    {
        foreach (var url in _foxFeeds)
        {
            try
            {
                var xml  = await _http.GetStringAsync(url);
                var doc  = XDocument.Parse(xml);
                var list = doc.Descendants("item")
                              .Take(5)
                              .Select(e => e.Element("title")?.Value)
                              .Where(t => !string.IsNullOrWhiteSpace(t))
                              .Cast<string>()
                              .ToList();
                if (list.Count > 0) return list;
            }
            catch (Exception ex) { Log.Warn($"RSS fetch failed ({url}): {ex.Message}"); }
        }

        return ["The Fox News owls have apparently flown away with all the headlines. Most peculiar."];
    }
}
