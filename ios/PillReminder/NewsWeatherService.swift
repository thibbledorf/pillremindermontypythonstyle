import CoreLocation
import Foundation

/// Fetches Fox News headlines (RSS) and local weather (wttr.in, no API key)
/// using CoreLocation for "the area you're currently in."
final class NewsWeatherService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Public

    func fetchWeatherText() async -> String {
        let location = await currentLocation()
        let urlString: String
        if let location {
            urlString = "https://wttr.in/\(location.coordinate.latitude),\(location.coordinate.longitude)?format=j1"
        } else {
            urlString = "https://wttr.in/?format=j1"
        }
        guard
            let url = URL(string: urlString),
            let (data, _) = try? await URLSession.shared.data(from: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = (json["current_condition"] as? [[String: Any]])?.first,
            let descArray = current["weatherDesc"] as? [[String: Any]],
            let desc = descArray.first?["value"] as? String,
            let tempF = current["temp_F"] as? String,
            let feelsF = current["FeelsLikeF"] as? String,
            let humidity = current["humidity"] as? String
        else {
            return "The weather spirits are being most uncooperative today, much like those dreadful French knights."
        }

        var area = "your area"
        if let nearest = (json["nearest_area"] as? [[String: Any]])?.first,
           let areaNameArr = nearest["areaName"] as? [[String: Any]],
           let name = areaNameArr.first?["value"] as? String {
            area = name
        }

        return "Weather in \(area): \(desc). Temperature \(tempF) degrees Fahrenheit, feels like \(feelsF). Humidity \(humidity) percent."
    }

    func fetchHeadlines(count: Int = 5) async -> [String] {
        let feedURLs = [
            "https://moxie.foxnews.com/google-publisher/latest.xml",
            "http://feeds.foxnews.com/foxnews/latest",
        ]
        for feed in feedURLs {
            guard let url = URL(string: feed),
                  let (data, _) = try? await URLSession.shared.data(from: url) else { continue }
            let titles = RSSParser.parseTitles(from: data)
            if !titles.isEmpty { return Array(titles.prefix(count)) }
        }
        return ["The Fox News owls have apparently flown away with all the headlines. Most peculiar."]
    }

    // MARK: - Location

    private func currentLocation() async -> CLLocation? {
        guard CLLocationManager.locationServicesEnabled() else { return nil }
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways || status == .notDetermined else {
            return nil
        }

        return await withCheckedContinuation { (cont: CheckedContinuation<CLLocation?, Never>) in
            self.locationContinuation = cont
            self.locationManager.requestLocation()
            // Safety timeout in case the delegate never calls back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.locationContinuation?.resume(returning: nil)
                self.locationContinuation = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.first)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}

/// Minimal RSS <title> extractor — avoids pulling in a third-party XML/RSS
/// dependency for a handful of headline strings.
enum RSSParser {
    static func parseTitles(from data: Data) -> [String] {
        final class Delegate: NSObject, XMLParserDelegate {
            var titles: [String] = []
            var insideItem = false
            var insideTitle = false
            var buffer = ""

            func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
                if elementName == "item" { insideItem = true }
                if elementName == "title" && insideItem {
                    insideTitle = true
                    buffer = ""
                }
            }

            func parser(_ parser: XMLParser, foundCharacters string: String) {
                if insideTitle { buffer += string }
            }

            func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
                if elementName == "title" && insideItem {
                    let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { titles.append(trimmed) }
                    insideTitle = false
                }
                if elementName == "item" { insideItem = false }
            }
        }

        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.titles
    }
}
