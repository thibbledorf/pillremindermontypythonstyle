import AppKit
import SwiftUI

/// Large always-on-top reminder window with one big button. Shows on every Space and
/// over full-screen apps. Return, Enter, or Space also acknowledge.
enum AckPanel {
    private static var panel: NSPanel?
    private static let model = Model()

    final class Model: ObservableObject {
        @Published var phrase = ""
        @Published var attempt = 1
    }

    private final class KeyPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
        override func keyDown(with event: NSEvent) {
            if ["\r", "\u{3}", " "].contains(event.characters ?? "") {
                ReminderEngine.shared.acknowledge(source: "keyboard")
            } else {
                super.keyDown(with: event)
            }
        }
    }

    static func show() {
        DispatchQueue.main.async {
            if panel == nil {
                let p = KeyPanel(contentRect: NSRect(x: 0, y: 0, width: 720, height: 460),
                                 styleMask: [.titled, .fullSizeContentView],
                                 backing: .buffered, defer: false)
                p.title = "Pill O'Clock"
                p.titlebarAppearsTransparent = true
                p.level = .floating
                p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
                p.isReleasedWhenClosed = false
                p.hidesOnDeactivate = false
                p.contentView = NSHostingView(rootView: PanelView(model: model))
                panel = p
            }
            panel!.center()
            NSApp.activate(ignoringOtherApps: true)
            panel!.makeKeyAndOrderFront(nil)
            panel!.orderFrontRegardless()
        }
    }

    static func update(phrase: String, attempt: Int) {
        DispatchQueue.main.async {
            model.phrase = phrase
            model.attempt = attempt
            panel?.orderFrontRegardless()
        }
    }

    static func hide() {
        DispatchQueue.main.async { panel?.orderOut(nil) }
    }

    private struct PanelView: View {
        @ObservedObject var model: Model

        var body: some View {
            VStack(spacing: 24) {
                Text("💊 Pill O'Clock")
                    .font(.system(size: 40, weight: .heavy))
                Text(model.phrase)
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
                Button {
                    ReminderEngine.shared.acknowledge(source: "button")
                } label: {
                    Text("I TOOK MY PILLS")
                        .font(.system(size: 34, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 110)
                        .foregroundColor(.white)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.green))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text(model.attempt > 1 ? "Reminder #\(model.attempt) — or say “yes”, or press Return"
                                       : "Or say “yes”, or press Return")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(36)
            .frame(width: 720, height: 460)
        }
    }
}
