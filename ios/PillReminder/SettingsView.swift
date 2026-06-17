import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ReminderManager
    @State private var apiKeyInput: String = ""
    @State private var savedConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-...", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save API Key") {
                        manager.saveAPIKey(apiKeyInput)
                        savedConfirmation = true
                        apiKeyInput = ""
                    }
                    .disabled(apiKeyInput.isEmpty)
                } header: {
                    Text("Claude API Key")
                } footer: {
                    Text("Optional. When set, the app occasionally asks Claude Haiku to mint brand-new Monty Python reminder phrases so they never get stale. Stored securely in the Keychain — never leaves your device except to call the Anthropic API. Get a key at console.anthropic.com.")
                }

                Section("Status") {
                    LabeledContent("AI phrase generation", value: manager.hasAPIKey ? "Enabled" : "Disabled — no key set")
                    LabeledContent("Cached AI phrases", value: "\(PhraseCache.load().count)")
                }
            }
            .navigationTitle("Settings")
            .alert("Saved", isPresented: $savedConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("API key saved to Keychain.")
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(ReminderManager())
}
