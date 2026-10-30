import AppKit
import SwiftUI

enum SettingsWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 760),
                             styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            w.title = "Pill Reminder Settings"
            w.isReleasedWhenClosed = false
            window = w
        }
        // Fresh view each time so it reflects the config on disk.
        window!.contentView = NSHostingView(rootView: SettingsView(close: { window?.orderOut(nil) }))
        window!.center()
        NSApp.activate(ignoringOtherApps: true)
        window!.makeKeyAndOrderFront(nil)
    }
}

private final class SettingsModel: ObservableObject {
    @Published var cfg = Config.current()
    @Published var times: [Date] = []
    @Published var apiKey = ""
    @Published var keyStatus = ""
    @Published var englishVoices: [String] = []
}

private struct SettingsView: View {
    let close: () -> Void

    @ObservedObject private var m = SettingsModel()

    private static let accents = ["british", "american", "australian", "irish"]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Pill m.times") {
                    ForEach(m.times.indices, id: \.self) { i in
                        HStack {
                            DatePicker("Dose \(i + 1)", selection: $m.times[i], displayedComponents: .hourAndMinute)
                            Button(role: .destructive) { m.times.remove(at: i) } label: { Image(systemName: "minus.circle.fill") }
                                .buttonStyle(.borderless)
                                .disabled(m.times.count <= 1)
                        }
                    }
                    Button("Add a dose time") { m.times.append(Date()) }
                }

                Section("You") {
                    TextField("Condition (spoken in reminders)", text: $m.cfg.malady)
                    TextField("Weather location (blank = automatic)", text: $m.cfg.location)
                }

                Section("Voice") {
                    Picker("Gender", selection: $m.cfg.voiceGender) {
                        Text("Male").tag("male"); Text("Female").tag("female")
                    }
                    Picker("Accent", selection: $m.cfg.voiceAccent) {
                        ForEach(Self.accents, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Picker("Specific voice", selection: $m.cfg.voiceName) {
                        Text("Automatic").tag("")
                        ForEach(m.englishVoices, id: \.self) { Text($0).tag($0) }
                    }
                    HStack {
                        Text("Speed")
                        Slider(value: Binding(get: { Double(m.cfg.speechRate) }, set: { m.cfg.speechRate = Int($0) }), in: 110...260, step: 5)
                        Text("\(m.cfg.speechRate) wpm").monospacedDigit().frame(width: 80)
                    }
                    HStack {
                        Text("Minimum volume")
                        Slider(value: Binding(get: { Double(m.cfg.minVolume) }, set: { m.cfg.minVolume = Int($0) }), in: 0...100, step: 5)
                        Text(m.cfg.minVolume == 0 ? "off" : "\(m.cfg.minVolume)%").monospacedDigit().frame(width: 80)
                    }
                    Button("Test voice") {
                        let snapshot = m.cfg
                        DispatchQueue.global().async {
                            snapshot.save()
                            Speaker.shared.speak("I am Arthur, King of the Britons, and this is how I sound.")
                        }
                    }
                }

                Section("Behavior") {
                    Toggle("Listen for a spoken “yes”", isOn: $m.cfg.voiceAck)
                    Toggle("News and weather after pills are taken", isOn: $m.cfg.newsAndWeather)
                    Stepper("Repeat every \(m.cfg.repeatSeconds) seconds", value: $m.cfg.repeatSeconds, in: 30...600, step: 15)
                    Stepper("Give up after \(m.cfg.giveUpMinutes) minutes", value: $m.cfg.giveUpMinutes, in: 15...240, step: 15)
                }

                Section("Fresh phrases") {
                    Picker("Source", selection: $m.cfg.phraseSource) {
                        Text("Ollama (free, local)").tag("ollama")
                        Text("Claude (paid API)").tag("claude")
                        Text("Off — built-in phrases only").tag("off")
                    }
                    if m.cfg.phraseSource == "ollama" {
                        TextField("Ollama server", text: $m.cfg.ollamaURL)
                        TextField("Ollama model", text: $m.cfg.ollamaModel)
                    }
                    if m.cfg.phraseSource == "claude" {
                        SecureField("Anthropic API key", text: $m.apiKey)
                        Button("Save key") {
                            Keychain.save(m.apiKey)
                            m.apiKey = ""
                        }
                    }
                    HStack {
                        Button("Save and get new phrases now") {
                            m.cfg.save()
                            m.keyStatus = "Generating… check the menu in a minute."
                            PhraseCache.shared.refill(count: 3, reason: "Settings")
                        }
                        Text(m.keyStatus).foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .controlSize(.large)

            HStack {
                Spacer()
                Button("Cancel") { close() }.keyboardShortcut(.cancelAction)
                Button("Save") { save() }.keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            .padding()
        }
        .frame(minWidth: 560, minHeight: 600)
        .onAppear(perform: load)
    }

    private func load() {
        m.cfg = Config.current()
        let cal = Calendar.current
        m.times = m.cfg.parsedTimes.compactMap { cal.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: Date()) }
        if m.times.isEmpty { m.times = [Date()] }
        let s = PhraseCache.shared.status()
        m.keyStatus = "\(s.count) cached phrases" + (s.lastError.map { " — last error: \($0.prefix(80))" } ?? "")
        DispatchQueue.global().async {
            let list = Shell.run("/usr/bin/say", ["-v", "?"], timeout: 10).output
                .split(separator: "\n")
                .filter { $0.contains(" en_") }
                .compactMap { line -> String? in
                    let head = line.split(separator: "#").first ?? ""
                    let parts = head.split(separator: " ")
                    return parts.count > 1 ? parts.dropLast().joined(separator: " ") : nil
                }
            DispatchQueue.main.async { m.englishVoices = Array(Set(list)).sorted() }
        }
    }

    private func save() {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        m.cfg.pillTimes = Array(Set(m.times.map { f.string(from: $0) })).sorted()
        m.cfg.save()
        close()
    }
}
