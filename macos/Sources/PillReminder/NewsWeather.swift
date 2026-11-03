import Foundation

enum NewsWeather {
    private static let foxFeeds = [
        "https://moxie.foxnews.com/google-publisher/latest.xml",
        "https://feeds.foxnews.com/foxnews/latest",
    ]

    static func weather(location: String) -> String {
        let failure = "The weather spirits are being most uncooperative today, much like those dreadful French knights."
        guard let place = coordinates(for: location.trimmingCharacters(in: .whitespaces)) else {
            Log.warn("Weather location lookup failed")
            return failure
        }
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            URLQueryItem(name: "latitude", value: String(place.lat)),
            URLQueryItem(name: "longitude", value: String(place.lon)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
        ]
        guard let url = c.url,
              let d = HTTP.get(url, timeout: 12),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let cur = j["current"] as? [String: Any],
              let temp = cur["temperature_2m"] as? Double,
              let feel = cur["apparent_temperature"] as? Double,
              let humid = cur["relative_humidity_2m"] as? Double,
              let code = cur["weather_code"] as? Int
        else {
            Log.warn("Weather fetch failed")
            return failure
        }
        return "Weather in \(place.name): \(describe(code)). Temperature \(Int(temp.rounded())) degrees Fahrenheit, "
            + "feels like \(Int(feel.rounded())). Humidity \(Int(humid.rounded())) percent."
    }

    /// Open-Meteo needs coordinates. A configured place is looked up with its
    /// geocoder, which understands "Tampa, FL"; otherwise the IP address is,
    /// which gives the internet provider's location and can be miles off.
    private static func coordinates(for location: String) -> (name: String, lat: Double, lon: Double)? {
        if location.isEmpty {
            guard let d = HTTP.get(URL(string: "https://ipinfo.io/json")!, timeout: 8),
                  let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let loc = j["loc"] as? String
            else { return nil }
            let parts = loc.split(separator: ",").compactMap { Double($0) }
            guard parts.count == 2 else { return nil }
            return ((j["city"] as? String) ?? "your area", parts[0], parts[1])
        }
        var queries = [location]
        if let town = location.split(separator: ",").first.map({ $0.trimmingCharacters(in: .whitespaces) }),
           !town.isEmpty, town != location {
            queries.append(town)
        }
        for query in queries {
            var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            c.queryItems = [
                URLQueryItem(name: "name", value: query),
                URLQueryItem(name: "count", value: "1"),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "format", value: "json"),
            ]
            if let url = c.url,
               let d = HTTP.get(url, timeout: 8),
               let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
               let first = (j["results"] as? [[String: Any]])?.first,
               let name = first["name"] as? String,
               let lat = first["latitude"] as? Double,
               let lon = first["longitude"] as? Double {
                return (name, lat, lon)
            }
        }
        return nil
    }

    /// WMO weather interpretation codes, as Open-Meteo reports them.
    private static func describe(_ code: Int) -> String {
        switch code {
        case 0: return "clear sky"
        case 1: return "mainly clear"
        case 2: return "partly cloudy"
        case 3: return "overcast"
        case 45, 48: return "fog"
        case 51, 53, 55: return "drizzle"
        case 56, 57: return "freezing drizzle"
        case 61, 63, 65: return "rain"
        case 66, 67: return "freezing rain"
        case 71, 73, 75, 77: return "snow"
        case 80, 81, 82: return "rain showers"
        case 85, 86: return "snow showers"
        case 95: return "thunderstorms"
        case 96, 99: return "thunderstorms with hail"
        default: return "weather of an unknown and possibly French nature"
        }
    }

    static func headlines(count: Int = 5) -> [String] {
        for feed in foxFeeds {
            guard let url = URL(string: feed), let d = HTTP.get(url, timeout: 12) else { continue }
            let titles = RSSTitles.parse(d).prefix(count)
            if !titles.isEmpty { return Array(titles) }
        }
        Log.warn("Headline fetch failed on all feeds")
        return ["The Fox News owls have apparently flown away with all the headlines. Most peculiar."]
    }
}

/// Pulls <item><title> values out of an RSS document.
private final class RSSTitles: NSObject, XMLParserDelegate {
    private var titles: [String] = []
    private var inItem = false
    private var inTitle = false
    private var buf = ""

    static func parse(_ data: Data) -> [String] {
        let p = XMLParser(data: data)
        let d = RSSTitles()
        p.delegate = d
        p.parse()
        return d.titles
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if name == "item" { inItem = true }
        if inItem && name == "title" { inTitle = true; buf = "" }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) { if inTitle { buf += string } }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if inTitle, let s = String(data: CDATABlock, encoding: .utf8) { buf += s }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "title" && inTitle {
            let t = buf.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { titles.append(t) }
            inTitle = false
        }
        if name == "item" { inItem = false }
    }
}
