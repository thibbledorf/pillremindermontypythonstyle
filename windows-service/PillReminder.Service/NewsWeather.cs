using System.Globalization;
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

    private const string WeatherFailure =
        "The weather spirits are being most uncooperative today, " +
        "much like those dreadful French knights.";

    public static async Task<string> GetWeatherAsync()
    {
        try
        {
            var place = await GetCoordinatesAsync(Config.Load().Location.Trim());
            if (place is null)
            {
                Log.Warn("Weather location lookup failed");
                return WeatherFailure;
            }
            var (area, lat, lon) = place.Value;

            var url = "https://api.open-meteo.com/v1/forecast" +
                      $"?latitude={lat.ToString(CultureInfo.InvariantCulture)}" +
                      $"&longitude={lon.ToString(CultureInfo.InvariantCulture)}" +
                      "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code" +
                      "&temperature_unit=fahrenheit";
            var data  = await _http.GetFromJsonAsync<JsonElement>(url);
            var cur   = data.GetProperty("current");
            var temp  = cur.GetProperty("temperature_2m").GetDouble();
            var feel  = cur.GetProperty("apparent_temperature").GetDouble();
            var humid = cur.GetProperty("relative_humidity_2m").GetDouble();
            var code  = cur.GetProperty("weather_code").GetInt32();

            return $"Weather in {area}: {Describe(code)}. Temperature {Math.Round(temp)} degrees Fahrenheit, " +
                   $"feels like {Math.Round(feel)}. Humidity {Math.Round(humid)} percent.";
        }
        catch (Exception ex)
        {
            Log.Warn($"Weather fetch failed: {ex.Message}");
            return WeatherFailure;
        }
    }

    // Open-Meteo needs coordinates. A configured place is looked up with its
    // geocoder, which understands "Tampa, FL"; otherwise the IP address is,
    // which gives the internet provider's location and can be miles off.
    private static async Task<(string Area, double Lat, double Lon)?> GetCoordinatesAsync(string location)
    {
        if (string.IsNullOrEmpty(location))
        {
            var ip  = await _http.GetFromJsonAsync<JsonElement>("https://ipinfo.io/json");
            var loc = ip.TryGetProperty("loc", out var l) ? l.GetString() ?? "" : "";
            var parts = loc.Split(',');
            if (parts.Length != 2 ||
                !double.TryParse(parts[0], NumberStyles.Float, CultureInfo.InvariantCulture, out var ipLat) ||
                !double.TryParse(parts[1], NumberStyles.Float, CultureInfo.InvariantCulture, out var ipLon))
                return null;
            var city = ip.TryGetProperty("city", out var c) ? c.GetString() : null;
            return (string.IsNullOrEmpty(city) ? "your area" : city, ipLat, ipLon);
        }

        var queries = new List<string> { location };
        var town = location.Split(',')[0].Trim();
        if (town.Length > 0 && town != location) queries.Add(town);

        foreach (var query in queries)
        {
            var url = "https://geocoding-api.open-meteo.com/v1/search" +
                      $"?name={Uri.EscapeDataString(query)}&count=1&language=en&format=json";
            var data = await _http.GetFromJsonAsync<JsonElement>(url);
            if (data.TryGetProperty("results", out var results) && results.GetArrayLength() > 0)
            {
                var first = results[0];
                return (first.GetProperty("name").GetString() ?? query,
                        first.GetProperty("latitude").GetDouble(),
                        first.GetProperty("longitude").GetDouble());
            }
        }
        return null;
    }

    // WMO weather interpretation codes, as Open-Meteo reports them.
    private static string Describe(int code) => code switch
    {
        0 => "clear sky",
        1 => "mainly clear",
        2 => "partly cloudy",
        3 => "overcast",
        45 or 48 => "fog",
        51 or 53 or 55 => "drizzle",
        56 or 57 => "freezing drizzle",
        61 or 63 or 65 => "rain",
        66 or 67 => "freezing rain",
        71 or 73 or 75 or 77 => "snow",
        80 or 81 or 82 => "rain showers",
        85 or 86 => "snow showers",
        95 => "thunderstorms",
        96 or 99 => "thunderstorms with hail",
        _ => "weather of an unknown and possibly French nature",
    };

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
