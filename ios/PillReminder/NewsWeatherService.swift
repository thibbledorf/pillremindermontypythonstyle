import CoreLocation
import Foundation

/// Fetches Fox News headlines (RSS) and local weather (Open-Meteo, no API key)
/// using CoreLocation for "the area you're currently in."
final class NewsWeatherService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    // URLSession.shared waits up to 60 s on a stalled server, leaving the
    // user in silence. Match macOS and Windows.
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 12
        return URLSession(configuration: config)
    }()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Public

    static let weatherFailure = "The weather spirits are being most uncooperative today, much like those dreadful French knights."

    /// Nil when the weather could not be fetched.
    func fetchWeatherText() async -> String? {
        // Open-Meteo needs coordinates; there is no IP-based fallback.
        guard let location = await currentLocation() else { return nil }
        let lat = location.coordinate.latitude, lon = location.coordinate.longitude
        async let area = areaName(for: location)
        guard
            let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)"
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code"
                + "&temperature_unit=fahrenheit"),
            let (data, _) = try? await session.data(from: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = json["current"] as? [String: Any],
            let temp = current["temperature_2m"] as? Double,
            let feels = current["apparent_temperature"] as? Double,
            let humidity = current["relative_humidity_2m"] as? Double,
            let code = current["weather_code"] as? Int
        else {
            return nil
        }

        return "Weather in \(await area): \(Self.describe(code)). Temperature \(Int(temp.rounded())) degrees Fahrenheit, "
            + "feels like \(Int(feels.rounded())). Humidity \(Int(humidity.rounded())) percent."
    }

    /// Town name from Apple's geocoder; a slow or failed lookup must not
    /// hold up the weather.
    private func areaName(for location: CLLocation) async -> String {
        await withTaskGroup(of: String?.self) { group in
            group.addTask {
                let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
                return placemark?.locality ?? placemark?.subAdministrativeArea
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? "your area"
        }
    }

    /// WMO weather interpretation codes, as Open-Meteo reports them.
    private static func describe(_ code: Int) -> String {
        switch code {
        case 0: "clear sky"
        case 1: "mainly clear"
        case 2: "partly cloudy"
        case 3: "overcast"
        case 45, 48: "fog"
        case 51, 53, 55: "drizzle"
        case 56, 57: "freezing drizzle"
        case 61, 63, 65: "rain"
        case 66, 67: "freezing rain"
        case 71, 73, 75, 77: "snow"
        case 80, 81, 82: "rain showers"
        case 85, 86: "snow showers"
        case 95: "thunderstorms"
        case 96, 99: "thunderstorms with hail"
        default: "weather of an unknown and possibly French nature"
        }
    }

    func fetchHeadlines(count: Int = 5) async -> [String] {
        let feedURLs = [
            "https://moxie.foxnews.com/google-publisher/latest.xml",
            "http://feeds.foxnews.com/foxnews/latest",
        ]
        for feed in feedURLs {
            guard let url = URL(string: feed),
                  let (data, _) = try? await session.data(from: url) else { continue }
            let titles = RSSParser.parseTitles(from: data)
            if !titles.isEmpty { return Array(titles.prefix(count)) }
        }
        return ["The Fox News owls have apparently flown away with all the headlines. Most peculiar."]
    }

    // MARK: - Location

    private var authorizationContinuation: CheckedContinuation<Void, Never>?

    /// A recent fix is reused at once; otherwise a town-level fix is
    /// requested, which is quicker than a precise one and enough for weather.
    @MainActor
    private func currentLocation() async -> CLLocation? {
        if locationManager.authorizationStatus == .notDetermined {
            // Asking for a fix before the user answers the permission
            // prompt fails at once, so wait for the answer.
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                authorizationContinuation = cont
                locationManager.requestWhenInUseAuthorization()
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { self.resumeAuthorization() }
            }
        }
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }
        if let last = locationManager.location, -last.timestamp.timeIntervalSinceNow < 30 * 60 {
            return last
        }

        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        return await withCheckedContinuation { (cont: CheckedContinuation<CLLocation?, Never>) in
            locationContinuation = cont
            locationManager.requestLocation()
            // Safety timeout in case the delegate never calls back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                self.resumeLocation(nil)
            }
        }
    }

    private func resumeLocation(_ location: CLLocation?) {
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    private func resumeAuthorization() {
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined { resumeAuthorization() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resumeLocation(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeLocation(nil)
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
