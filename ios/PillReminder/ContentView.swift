import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Reminders", systemImage: "pills.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var manager: ReminderManager

    private let timesText = ReminderManager.pillTimes
        .map { String(format: "%02d:%02d", $0.hour, $0.minute) }
        .joined(separator: "   ")

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Pill Reminder")
                        .font(.largeTitle.bold())
                    Text("Monty Python Edition")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("Scheduled times")
                        .font(.headline)
                    Text(timesText)
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                Text(manager.lastStatusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if manager.isReminderFlowActive {
                    ProgressView("In progress...")
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await manager.runReminderFlow() }
                    } label: {
                        Label("Trigger reminder now", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manager.isReminderFlowActive)

                    Button {
                        Task { await manager.acknowledge() }
                    } label: {
                        Label("I took my pills", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(manager.isReminderFlowActive)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
        }
    }
}

#Preview {
    ContentView().environmentObject(ReminderManager())
}
