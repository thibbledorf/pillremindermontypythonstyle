# Development Setup

## Prerequisites

### macOS (for iOS/macOS development)
- Xcode 14 or later (install from App Store)
- macOS 12 or later
- Apple Developer Account (free, or paid for App Store submission)

### Windows (for Windows development)
- Visual Studio 2022 Community or Professional
- .NET 7 or later

### Linux (for Linux development)
- Python 3.9 or later
- PyQt6: `sudo apt-get install python3-pyqt6`
- pyttsx3: `pip install pyttsx3`

## iOS/macOS Setup

### Clone and Navigate
```bash
cd /Users/eric/github/pillremindermontypythonstyle
```

### Open Xcode Project
```bash
cd ios/PillReminder
open PillReminder.xcodeproj
```

### Select Team & Signing
1. Open PillReminder.xcodeproj in Xcode
2. Select "PillReminder" target
3. Go to "Signing & Capabilities"
4. Under "Team", select your Apple Developer account
5. Xcode auto-generates provisioning profiles

### Build & Run
```bash
# Via Xcode: Cmd+R to build and run on simulator
# Via CLI:
xcodebuild -scheme PillReminder -configuration Debug

# Run on simulator:
xcrun simctl launch booted com.example.pillreminder
```

### Testing
```bash
# Run unit tests
xcodebuild -scheme PillReminder -configuration Debug test

# Run UI tests
xcodebuild -scheme PillReminder -configuration Debug test -testPlan UITests
```

## Code Style

### Swift
- Follow [Google Swift Style Guide](https://google.github.io/swift-style-guide/)
- Use SwiftLint: `brew install swiftlint`
- Run before commit: `swiftlint lint`

### File Organization
```
ios/PillReminder/
├── App.swift                 # Main entry point
├── Models/                   # Data structures (Reminder, VoiceSettings)
├── Services/                 # Business logic (VoiceManager, ReminderStore)
├── ViewModels/               # MVVM view models
├── Views/                    # SwiftUI views
├── Resources/                # Assets, JSON data (Monty.json)
└── PillReminderApp.swift     # @main app entry
```

## Hot Reload Development

SwiftUI supports live preview:
1. Open any View file
2. Open Canvas (Cmd+Opt+Return)
3. Edit code → preview updates in real-time
4. No rebuild needed for SwiftUI changes

## Debugging

### Console Logging
```swift
print("Debug: \(value)")
```

### Xcode Debugger
1. Set breakpoint (click line number)
2. Run app
3. Debugger pauses at breakpoint
4. Inspect variables in bottom panel

### Accessibility Inspector
1. Xcode → Open Developer Tools → Accessibility Inspector
2. Verify UI is accessible (labels, contrast ratios, etc.)

## Git Workflow

### Creating a Feature Branch
```bash
git checkout -b feature/your-feature-name
# e.g., git checkout -b feature/add-weather-integration
```

### Before Committing
1. Run tests: `xcodebuild test`
2. Run SwiftLint: `swiftlint lint`
3. Review changes: `git diff`

### Commit and Push
```bash
git add .
git commit -m "Brief description of changes"
git push origin feature/your-feature-name
```

### Create Pull Request
```bash
gh pr create --title "Feature: Description" --body "Details here"
```

## Common Issues

### Issue: Cannot open PillReminder.xcodeproj
**Solution:** Make sure you're in the ios/PillReminder directory:
```bash
cd ios/PillReminder
open PillReminder.xcodeproj
```

### Issue: "No matching provisioning profile"
**Solution:** Open project settings → Signing & Capabilities → let Xcode auto-manage

### Issue: Simulator won't launch
**Solution:** Reset simulator:
```bash
xcrun simctl erase all
```

### Issue: Voice synthesis test fails
**Solution:** Ensure iOS simulator has audio output enabled (Preferences → I/O → Audio & Video)

## Continuous Integration

GitHub Actions workflows (in `.github/workflows/`):
- **build.yml**: Builds iOS app on every push
- **test.yml**: Runs unit tests
- **lint.yml**: Runs SwiftLint

Workflows are automatically triggered on:
- Push to main branch
- Push to feature/* branches
- Pull requests

## Environment Variables

Create `.env` file in project root (not committed to git):
```
ELEVEN_LABS_API_KEY=your-key-here  # Optional, for Phase 2
WEATHER_API_KEY=your-key-here      # Optional, for Phase 2
```

Reference in code:
```swift
let apiKey = ProcessInfo.processInfo.environment["ELEVEN_LABS_API_KEY"]
```

## Release Process

1. Update version in `Info.plist`
2. Update `CHANGELOG.md`
3. Commit: `git commit -m "Release v1.0.0"`
4. Tag: `git tag v1.0.0`
5. Push: `git push origin main --tags`
6. GitHub automatically creates release notes

For App Store submission, see [APP_STORE_SUBMISSION.md](APP_STORE_SUBMISSION.md)
