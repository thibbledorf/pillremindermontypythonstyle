import Foundation

enum NewsWeather {
    private static let foxFeeds = [
        "https://moxie.foxnews.com/google-publisher/latest.xml",
        "https://feeds.foxnews.com/foxnews/latest",
    ]

    static func weather(location: String) -> String {
        var loc = location.trimmingCharacters(in: .whitespaces)
        if loc.isEmpty,
           let d = HTTP.get(URL(string: "https://ipinfo.io/json")!, timeout: 8),
           let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let city = j["city"] as? String, !city.isEmpty {
            loc = "\(city), \(j["region"] as? String ?? "")"
        }
        let path = loc.isEmpty ? "" : (loc.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
        guard let url = URL(string: "https://wttr.in/\(path)?format=j1"),
              let d = HTTP.get(url, timeout: 12),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let cur = (j["current_condition"] as? [[String: Any]])?.first
        else {
            Log.warn("Weather fetch failed")
            return "The weather spirits are being most uncooperative today, much like those dreadful French knights."
        }
        let desc = ((cur["weatherDesc"] as? [[String: Any]])?.first?["value"] as? String) ?? "unknown skies"
        let tempF = cur["temp_F"] as? String ?? "?"
        let feelF = cur["FeelsLikeF"] as? String ?? "?"
        let humid = cur["humidity"] as? String ?? "?"
        let area = (((j["nearest_area"] as? [[String: Any]])?.first?["areaName"] as? [[String: Any]])?.first?["value"] as? String)
            ?? (loc.isEmpty ? "your area" : loc)
        return "Weather in \(area): \(desc). Temperature \(tempF) degrees Fahrenheit, feels like \(feelF). Humidity \(humid) percent."
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
