# Pill Reminder iOS - Quick Start Guide

## Prerequisites
- Mac with macOS 12 or later
- Xcode 14 or later (install from App Store)
- Apple Developer Account (free to start)
- iPhone or iPad with iOS 16+

## Opening the Project

```bash
cd ios
open PillReminder.xcodeproj
```

The project will open in Xcode. You should see:
- Left panel: Project navigator with all Swift files
- Center: Code editor
- Right panel: Inspector

## First Setup (5 minutes)

### 1. Set Your Team
1. Select **PillReminder** in the project navigator
2. Select **PillReminder** target
3. Go to **Signing & Capabilities** tab
4. Under "Team", select your Apple Developer account
   - If none appears, go to Xcode → Settings → Accounts → Add Apple ID
5. Xcode auto-generates provisioning profiles

### 2. Verify Settings
- **Bundle ID:** `com.example.pillreminder` (change if desired)
- **Version:** 1.0
- **Deployment Target:** iOS 16.0+
- **Minimum Swift Version:** 5.0

## Building & Running

### Option A: Simulator (easiest first test)
```bash
# Via Xcode
1. Select scheme: "PillReminder"
2. Select destination: "iPhone 15" (or any simulator)
3. Press Cmd+R to build and run
```

### Option B: Real Device (recommended for full testing)
```bash
1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. Select scheme: "PillReminder"  
4. Select destination: "Your iPhone"
5. Press Cmd+R
```

**Note:** Notifications, microphone, and location (weather) work best on real devices.

## First Run

When you launch the app:
1. Grant permissions (microphone, speech recognition, location)
2. Go to Settings tab
3. Optionally add your Anthropic API key for AI phrase generation
4. Reminders are pre-set for 7:00 AM, 1:00 PM, 5:00 PM, 9:00 PM
5. When a notification fires, tap it to trigger the voice reminder

## Troubleshooting

### "Cannot find 'VoiceAckListener' in scope"
**Fix:** Make sure all .swift files are in the compile sources:
1. Select target
2. Go to Build Phases → Compile Sources
3. Click + and add any missing files

### "No team selected" error
**Fix:** Set your Apple Developer team (see Setup step 1)

### "Failed to generate provisioning profile"
**Fix:** 
1. Xcode → Settings → Accounts
2. Click your account → Manage Certificates
3. Create iOS Development certificate if missing

### Simulator notifications don't work
This is normal! Simulator has limited notification support. Use a real device for:
- Local notifications
- Microphone/speech recognition
- Location/weather

### "Request user permission" crashes
**Fix:** Make sure Info.plist has these keys:
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSLocationWhenInUseUsageDescription`

They should already be present, but verify in Xcode:
1. Select Info.plist in project navigator
2. Check all three keys exist with descriptions

## Project Structure

```
ios/
├── PillReminder.xcodeproj/        # Xcode project
│   └── project.pbxproj
├── PillReminder/                  # Source files
│   ├── PillReminderApp.swift      # App entry point
│   ├── ContentView.swift          # Main UI
│   ├── SettingsView.swift         # Settings/preferences
│   ├── ReminderManager.swift      # Core logic
│   ├── VoiceAckListener.swift     # Mic/speech recognition
│   ├── SpeechSynthesizerService.swift  # Voice synthesis
│   ├── NewsWeatherService.swift   # News/weather fetching
│   ├── Phrases.swift              # Monty Python quotes
│   ├── PhraseCache.swift          # Quote persistence
│   ├── ClaudeService.swift        # AI phrase generation
│   ├── KeychainHelper.swift       # Secure API key storage
│   ├── Info.plist                 # App permissions
│   └── Assets.xcassets/           # App icons, assets
├── SETUP.md                       # Detailed implementation notes
└── QUICK_START.md                # This file
```

## Key Features

✅ **Implemented:**
- Local notifications at 4 times daily
- Voice alerts with Monty Python phrases (40+ built-in)
- Voice acknowledgment listening
- News headlines (Fox News RSS)
- Weather reports (wttr.in API)
- Phrase caching (saves new phrases between launches)
- Claude API integration (optional, for generating new phrases)
- Secure API key storage (Keychain)

## Next Steps

1. **Test on Device:**
   - Connect iPhone
   - Build and run (Cmd+R)
   - Test notification at next scheduled time
   - Tap notification and verify voice works

2. **Customize:**
   - Change times in `ReminderManager.swift`
   - Modify phrases in `Phrases.swift`
   - Update condition text (default: "Parkinsons")

3. **App Store Prep (when ready):**
   - See `docs/APP_STORE_SUBMISSION.md`
   - Create app icon (1024x1024)
   - Write privacy policy
   - Take screenshots

4. **API Key (optional):**
   - Get Anthropic API key from console.anthropic.com
   - Paste in Settings tab when app is running
   - App generates new phrases weekly

## Development Tips

- **Live Preview:** In any .swift file, press Cmd+Opt+Return to preview
- **SwiftUI Canvas:** Edit UI and see changes instantly
- **Debugging:** Click line number to set breakpoints
- **Console:** View logs: View → Debug Area → Show Console (Cmd+Shift+C)
- **Testing Voice:** App has "Test Voice" button in settings

## Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| Build fails with missing files | Make sure all .swift files are in Build Phases → Compile Sources |
| Notifications don't appear | Use a real device, not simulator |
| Permission popup doesn't appear | Check Info.plist has all three permission keys |
| App crashes on launch | Check Console (Cmd+Shift+C) for error messages |
| Voice doesn't play | Check volume isn't muted; use real device |

## Need Help?

- **Build issues:** Check console (Cmd+Shift+C) for detailed errors
- **Setup issues:** See `DEVELOPMENT.md` in `/docs`
- **Architecture questions:** Read `ARCHITECTURE.md` in `/docs`
- **App Store submission:** See `APP_STORE_SUBMISSION.md` in `/docs`

---

**Ready to build?** Press Cmd+R and watch it run! 🎭📱
