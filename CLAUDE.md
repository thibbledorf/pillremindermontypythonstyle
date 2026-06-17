# Pill Reminder - Project Context

## Overview
A cross-platform medication reminder app with Monty Python-themed voice alerts. Users set reminders for medications, customize voice settings, and can include their condition (e.g., Parkinsons) and optional weather/news in voice alerts.

## Key Features (Phase 1: iOS)
- ⏰ Scheduled medication reminders
- 🎭 Monty Python voice alerts
- 🎤 Customizable voice rate, volume, voice selection
- 💊 Malady type field (e.g., Parkinsons)
- 🌦️ Optional news & weather in alerts
- 📱 SwiftUI native iOS app

## Tech Stack
- **iOS:** Swift, SwiftUI, AVSpeechSynthesizer (local TTS)
- **macOS:** Swift, SwiftUI (Phase 2)
- **Windows:** C#, MAUI/WPF (Phase 3)
- **Linux:** Python, PyQt6/GTK (Phase 3)
- **Backend:** Node.js/Express (Phase 4, optional cloud sync)

## Project Structure
```
pillremindermontypythonstyle/
├── docs/                    # Comprehensive documentation
│   ├── ARCHITECTURE.md      # System design
│   ├── DEVELOPMENT.md       # Setup & debugging
│   ├── CONTRIBUTING.md      # Contribution guidelines
│   ├── APP_STORE_SUBMISSION.md
│   └── VOICE_MODELS.md      # TTS configuration
├── ios/
│   └── PillReminder/        # Xcode project (to be created)
│       ├── Models/
│       ├── Services/
│       ├── ViewModels/
│       ├── Views/
│       └── Resources/
├── README.md                # Project overview
├── CLAUDE.md               # This file
└── CHANGELOG.md            # Version history (to be created)
```

## Data Model

### Reminder
```swift
struct Reminder: Identifiable, Codable {
    let id: UUID
    var enabled: Bool
    var time: String              // "HH:MM" format
    var maladyType: String        // e.g., "Parkinsons", or empty
    var voiceRate: Float          // 0.5 - 2.0
    var volumeLevel: Float        // 0.0 - 1.0
    var addOns: AddOns
}

struct AddOns: Codable {
    var news: Bool
    var weather: Bool
}
```

## Important Files & Paths

| File | Purpose |
|------|---------|
| `ios/PillReminder/Models/Reminder.swift` | Reminder data structure |
| `ios/PillReminder/Services/VoiceManager.swift` | TTS integration |
| `ios/PillReminder/Services/ReminderStore.swift` | Persistence (UserDefaults) |
| `ios/PillReminder/Views/ReminderListView.swift` | Main UI |
| `docs/ARCHITECTURE.md` | System design details |
| `docs/DEVELOPMENT.md` | Setup instructions |
| `docs/APP_STORE_SUBMISSION.md` | Store submission guide |

## Voice Settings
- **Rates:** 0.5 (slow) to 2.0 (fast), default 1.0
- **Volume:** 0.0 (silent) to 1.0 (max), default 0.8
- **Voices:** Platform-specific (iOS: AVSpeechSynthesizer)
- **Optional API:** Eleven Labs for premium voices (Phase 2)

## Current Development Phase
- **Phase 1 (iOS):** In Progress
  - [ ] Xcode project setup
  - [ ] Core models (Reminder, VoiceSettings)
  - [ ] UserDefaults persistence
  - [ ] VoiceManager with AVSpeechSynthesizer
  - [ ] SwiftUI views (list, add/edit, settings)
  - [ ] Monty Python jokes database
  - [ ] App Store documentation & submission

## Git Workflow
- Feature branches: `feature/description`
- Commits: Clear, descriptive messages
- PRs required for review before merging main
- Run tests before committing: `xcodebuild test`
- Run SwiftLint before committing: `swiftlint lint`

## Next Steps (Immediate)
1. Create Xcode project structure
2. Implement Reminder model & UserDefaults persistence
3. Create VoiceManager with AVSpeechSynthesizer
4. Build SwiftUI views (list, add/edit, settings)
5. Add Monty Python jokes database
6. Test on iOS device
7. Prepare for App Store submission

## App Store Details
- **Target:** Apple App Store (iOS 14+)
- **Category:** Health & Fitness / Lifestyle
- **Keywords:** pill reminder, medication, voice alert, health
- **Privacy:** Local-only in Phase 1, optional cloud sync in Phase 4
- **IDFA:** Does not use IDFA

## Testing Notes
- Test voice synthesis on real device (simulator audio may be limited)
- Verify reminders trigger at correct times
- Test with various voice rates (0.5, 1.0, 1.5, 2.0)
- Check persistence: create reminder → close app → reopen → reminder still there
- Accessibility: test with VoiceOver enabled

## Known Constraints
- Phase 1: Local storage only (no cloud sync)
- No external news/weather API integration in Phase 1
- Voice alerts use device TTS only (AVSpeechSynthesizer)
- macOS/Windows/Linux implementation deferred to Phases 2-3

## Tips for Future Development
- SwiftUI Previews (Canvas) are invaluable for UI development
- Use `@State`, `@StateObject`, `@EnvironmentObject` appropriately
- Keep VoiceManager stateless for easy testing
- Add new Monty Python jokes to `Resources/Monty.json`
- Remember to request notification permissions at runtime
- Test with accessibility inspector before each submission

## Resources
- [SwiftUI Documentation](https://developer.apple.com/tutorials/swiftui/)
- [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Architecture.md](docs/ARCHITECTURE.md) for detailed system design
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) for setup instructions

---

**Last Updated:** June 16, 2026  
**Current Phase:** 1 (iOS)  
**Status:** Documentation & planning complete, ready for Xcode project setup
