import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ReminderManager
    @State private var selectedVoice = SpeechSynthesizerService.selectedVoice
    @AppStorage(Phrases.maladyKey) private var malady = Phrases.defaultMalady
    @State private var maladyWhenOpened = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Condition", text: $malady)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Condition")
                } footer: {
                    Text("Named in reminders, for example Parkinson's. Leave empty to name none.")
                }

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
                    .disabled(manager.isReminderFlowActive)
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
        .onAppear { maladyWhenOpened = malady }
        .onDisappear {
            // Reminders already scheduled carry the old wording.
            if malady != maladyWhenOpened {
                Task { await manager.rescheduleNotifications() }
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(ReminderManager())
}
