import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ReminderManager
    @State private var selectedVoice = SpeechSynthesizerService.selectedVoice

    var body: some View {
        NavigationStack {
            Form {
                Section("Voice") {
                    Picker("Accent", selection: $selectedVoice) {
                        ForEach(VoiceOption.allCases, id: \.self) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    }
                    .onChange(of: selectedVoice) { _, newValue in
                        SpeechSynthesizerService.selectedVoice = newValue
                    }

                    Button("Test Voice") {
                        Task {
                            await manager.testVoice()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("About") {
                    LabeledContent("App", value: "Pill Reminder")
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Vibe", value: "Monty Python Edition")
                }

                Section("Privacy") {
                    Text("All data is stored locally on your device. Nothing is sent to any server. Your reminders, settings, and habits stay with you.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("About This App") {
                    Link("View on GitHub", destination: URL(string: "https://github.com/thibbledorf/pillremindermontypythonstyle")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().environmentObject(ReminderManager())
}
