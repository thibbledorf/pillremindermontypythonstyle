# Architecture Overview

## System Design

The Pill Reminder app is a cross-platform medication reminder with voice alerts. Each platform has a native UI but shares core data models and business logic patterns.

### Core Concepts

**Reminder Model**
```
struct Reminder {
  id: UUID
  enabled: bool
  time: Time (HH:MM format)
  maladyType: String (e.g., "Parkinsons", or empty for none)
  voiceRate: Float (0.5 - 2.0, speech rate multiplier)
  volumeLevel: Float (0.0 - 1.0)
  addOns: {
    news: bool
    weather: bool
  }
}
```

**Voice Alert Format**
```
"Take your medication! [Random Monty Python joke]. 
You have [malady if set]. 
[Optional: Today's weather is [conditions].]
[Optional: Top news: [headline].]"
```

### Phase 1: iOS (SwiftUI + AVSpeechSynthesizer)

**Architecture Layers:**

1. **Models** (`Models/`)
   - `Reminder.swift` - Core reminder data structure
   - `ReminderStore.swift` - Persistence layer (UserDefaults)
   - `VoiceSettings.swift` - Global voice configuration

2. **Voice Manager** (`Services/`)
   - `VoiceManager.swift` - Handles TTS using AVSpeechSynthesizer
   - Manages speech rate, volume, voice selection
   - Monty Python quote generator
   - News/Weather fetcher (stub for Phase 1)

3. **ViewModels** (`ViewModels/`)
   - `ReminderListViewModel.swift` - List screen state
   - `AddReminderViewModel.swift` - Add/Edit screen state
   - `SettingsViewModel.swift` - Settings screen state

4. **Views** (`Views/`)
   - `ContentView.swift` - App root
   - `ReminderListView.swift` - Main list of reminders
   - `ReminderDetailView.swift` - Add/Edit reminder
   - `SettingsView.swift` - Global voice settings
   - `VoiceTestView.swift` - Preview voice alert

5. **Resources** (`Resources/`)
   - `Monty.json` - Monty Python jokes database
   - App icons, assets

**Data Flow:**
```
ReminderListView 
  → ReminderListViewModel 
    → ReminderStore (UserDefaults)
    → VoiceManager

Add/Edit Flow:
AddReminderView
  → AddReminderViewModel
    → ReminderStore.save()
    → VoiceManager.test()
```

**Persistence:**
- UserDefaults stores reminders as JSON array
- Each reminder is Codable for serialization
- Automatic save on changes

**Voice Alerts:**
- Triggered by system notifications at scheduled time
- AVSpeechSynthesizer speaks: joke + malady + optional weather/news
- Voice rate and volume respect user settings

### Phase 2: macOS
- Reuse Swift models and VoiceManager as SwiftUI Shared Framework
- New macOS-specific Views (window-based instead of mobile)
- Optional menu bar app component
- Leverage same UserDefaults persistence (synced via iCloud)

### Phase 3: Windows (C#)
- Reimplement models in C#
- Use System.Speech for TTS
- WPF or MAUI for UI
- File-based storage (JSON)

### Phase 3: Linux (Python)
- Implement models in Python dataclasses
- Use pyttsx3 or espeak for TTS
- PyQt6 or GTK for UI
- SQLite or JSON file storage

### Phase 4: Cloud Sync (Future)
- Optional Node.js/Express backend
- User authentication (OAuth or simple email/password)
- Remind table in database
- Sync API endpoints
- All platforms support optional cloud sync
- Offline-first: local reminders work without internet

## Data Storage

**Phase 1 (Local Only):**
```json
{
  "reminders": [
    {
      "id": "uuid-here",
      "enabled": true,
      "time": "09:00",
      "maladyType": "Parkinsons",
      "voiceRate": 1.0,
      "volumeLevel": 0.8,
      "addOns": {
        "news": true,
        "weather": false
      }
    }
  ]
}
```

## API Design (Phase 4)

Endpoints (when cloud sync is implemented):
```
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/reminders           - Create reminder
GET    /api/reminders           - List user's reminders
PUT    /api/reminders/:id       - Update reminder
DELETE /api/reminders/:id       - Delete reminder
GET    /api/reminders/sync      - Get updates since timestamp
POST   /api/voice/test          - Test TTS with parameters
```

## Voice Selection

**iOS/macOS Built-in Voices:**
- Default system voice
- Multiple language options via AVSpeechSynthesizer
- No API keys required

**Phase 2: Optional API Integration**
- Eleven Labs API for premium natural voices
- Google Cloud TTS
- User stores API key locally in Keychain
- Falls back to system voice if API unavailable

## Notifications

**iOS:**
- Use UNUserNotificationCenter for scheduled local notifications
- Notification triggers reminder at exact time
- App plays voice alert when user opens notification

**macOS:**
- UNUserNotificationCenter (same as iOS)
- Menu bar icon notification badge

**Windows/Linux:**
- Platform-specific notification systems
- Toast notifications or system tray alerts

## Security Considerations

- Reminders stored locally only (no transmission in Phase 1)
- If user adds API keys: stored in platform-specific secure storage
  - iOS/macOS: Keychain
  - Windows: Data Protection API
  - Linux: Pass/Secret Service
- Phase 4: Auth tokens stored securely, HTTPS only for cloud sync

## Testing Strategy

**Unit Tests:**
- Reminder model serialization/deserialization
- Voice text generation
- Voice rate/volume calculations

**Integration Tests:**
- ReminderStore save/load
- VoiceManager speech synthesis
- Notification triggering

**UI Tests (via XCUITest on iOS):**
- Navigation between views
- Add/edit reminder flow
- Settings persistence
