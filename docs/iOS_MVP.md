# iOS MVP Specification

**Goal:** Ship a simple, privacy-first medication reminder with Monty Python voice alerts. No external dependencies, no API keys, no tracking. Focus: approval → market → Phase 2.

**Target Launch:** TestFlight 2-3 weeks, App Store approval 1-3 weeks after submission

## MVP Scope (Phase 1)

### ✅ What's Included

**Core Features:**
- Medication reminders at 4 fixed times (7 AM, 1 PM, 5 PM, 9 PM)
- Voice alerts using **AVSpeechSynthesizer** (iOS built-in, free, on-device)
- Voice rate control (0.5x - 2.0x speed, default 1.0x)
- Volume control (0-100%, default 80%)
- 40+ pre-built Monty Python phrases (shipped in app)
- Condition/malady field (text input: "Parkinsons", "Diabetes", or empty)

**Settings:**
- Toggle reminders on/off
- Adjust voice rate per reminder
- Adjust volume per reminder
- Customize condition text
- Simple UI (no dark mode, no advanced options)

**Permissions:**
- Local notifications (required)
- Microphone/speech recognition (NOT required in MVP - voice acknowledgment is Phase 2)

**User Data:**
- All stored locally on device (UserDefaults or local file)
- No cloud, no accounts, no signup, no tracking
- Privacy policy: "All data stays on your device"

### ❌ What's NOT Included (Phase 2)

- Voice acknowledgment (mic listening)
- News headlines
- Weather reports
- Claude API phrase generation
- Phrase caching
- Dark mode
- Multiple reminders (only 4 fixed times)
- Notification customization
- Background sync

## Technical Decisions

### TTS Strategy: AVSpeechSynthesizer (Free, On-Device, Open)

**Why this approach:**
- ✅ Free (built into iOS)
- ✅ No API keys or subscriptions
- ✅ Works 100% offline (privacy)
- ✅ No external dependencies
- ✅ Already in source code
- ✅ Multiple voices available (US English, British, Australian)

**Limitations (acceptable for MVP):**
- Less natural than Eleven Labs (users expect built-in to sound like Siri)
- Can't clone voices or add personality
- No streaming (fetches full text)

**Not using:**
- ❌ Eleven Labs (paid, external dependency, requires API key)
- ❌ Google Cloud TTS (paid, external API, requires auth)
- ❌ Custom audio files (too large, not scalable)

**Plan for Phase 2:**
- Keep AVSpeechSynthesizer as default
- Add OPTIONAL Eleven Labs integration for premium voices
- Users provide their own API key if desired
- App falls back to AVSpeechSynthesizer if API unavailable

### Data Storage: UserDefaults (Simple, Reliable)

- No database needed
- Built-in iOS encryption
- Syncs via iCloud if enabled
- No external dependencies
- Easy to backup/restore

**Data stored:**
```json
{
  "reminders": [
    {
      "id": "reminder-1",
      "enabled": true,
      "time": "07:00",
      "maladyType": "Parkinsons",
      "voiceRate": 1.0,
      "volumeLevel": 0.8
    },
    // ... 3 more reminders
  ],
  "globalVoiceRate": 1.0,
  "globalVolume": 0.8
}
```

## MVP UI (Simple, Approve-Friendly)

### Main Screen (ReminderListView)
- List of 4 reminders
- Each reminder shows:
  - Time (7:00 AM, 1:00 PM, 5:00 PM, 9:00 PM)
  - Toggle (on/off)
  - Voice rate (as number 0.5 - 2.0)
  - Volume (as percentage 0-100%)
- "Edit" button per reminder
- "Settings" tab at bottom

### Edit Reminder View (ReminderDetailView)
- Time picker (read-only, fixed times)
- Malady text field ("Parkinsons", "Diabetes", etc., or empty)
- Voice rate slider (0.5 - 2.0)
- Voice rate display (numeric)
- Volume slider (0-100%)
- Volume display (percentage)
- "Test Voice" button (plays sample alert)
- "Save" button
- "Cancel" button

### Settings Tab (SettingsView)
- App info (version, copyright)
- Privacy notice: "All data stored on your device"
- "Clear All Reminders" button (with confirmation)
- Link to privacy policy (in app)
- Link to GitHub repo

### Voice Test UI
- When user taps "Test Voice"
- Play sample text: "Take your [condition] medication! [random joke]."
- Example: "Take your Parkinsons medication! Nudge nudge, wink wink, say no more!"
- Uses current voice rate and volume settings

## Approval-Focused Requirements

### Privacy Policy (Required for App Store)
```
Pill Reminder Privacy Policy

Data Collection:
- This app collects NO personal data
- All data (reminders, settings) is stored locally on your iPhone
- No data is sent to any server or third party

Location:
- The app does NOT access your location
- Weather is NOT included in this version

Tracking:
- No analytics
- No crash reporting
- No user tracking
- No ads

Contact:
- [Your email]
- GitHub: [repo link]
```

### App Description (for App Store listing)
```
Pill Reminder: Monty Python Edition

Never forget your medication again! Get witty reminders with a Monty Python twist.

✓ Simple medication reminders (4 times daily)
✓ Customizable voice alerts
✓ Condition tracking (Parkinsons, diabetes, etc.)
✓ Fully offline - all data stays on your device
✓ No ads, no tracking, no logins

Set reminders once, get daily alerts with comedy and medicine combined.

Free, open source. Privacy first.
```

### Screenshots (Required)
1. **Main reminder list** - Shows 4 reminders, toggles
2. **Edit reminder** - Voice rate slider, volume, condition field, test button
3. **Settings** - Privacy notice, app info
4. **Voice test** - Example alert showing joke

### Permissions (Minimal for MVP)
- ✅ Local Notifications (required for reminders)
- ✅ Microphone (requested but OPTIONAL - used only for Phase 2)
  - In MVP: request but don't require
  - User can grant or deny, app still works fine
- ❌ Location (NOT requested in MVP)
- ❌ Health (NOT used in MVP)
- ❌ Calendar (NOT used in MVP)

### No External Dependencies
- ✅ Swift stdlib only
- ✅ AVFoundation (built-in)
- ✅ UserNotifications (built-in)
- ✅ Speech (built-in)
- ❌ No CocoaPods
- ❌ No SPM packages
- ❌ No API calls

## MVP Checklist (Before TestFlight)

### Code
- [ ] All 11 Swift files compile without errors
- [ ] No warnings in build
- [ ] Reminder model properly serializes/deserializes
- [ ] Voice synthesis works on device
- [ ] Notifications trigger at correct times
- [ ] Settings persist across app restarts
- [ ] Test voice button works
- [ ] All UI screens responsive

### Content
- [ ] 40+ Monty Python phrases included
- [ ] Privacy policy written and included
- [ ] App icon created (1024x1024 PNG)
- [ ] Screenshots captured (4 minimum)
- [ ] App description written
- [ ] Keywords defined

### Configuration
- [ ] Bundle ID: `com.example.pillreminder` (update before submission)
- [ ] Version: 1.0.0
- [ ] Minimum deployment: iOS 16.0
- [ ] Required permissions: Local Notifications
- [ ] Optional permissions: Microphone (for future)
- [ ] No hardcoded API keys
- [ ] No debug logging in production code

### Testing
- [ ] Tested on iPhone 14 or later
- [ ] NOT just simulator (device testing mandatory)
- [ ] Notifications work when app is closed
- [ ] Voice alerts play with correct rate/volume
- [ ] Settings survive app force-close and relaunch
- [ ] Accessibility tested (VoiceOver)

### Legal
- [ ] Privacy policy finalized
- [ ] Decide on open source license (Apache 2.0 or MIT?)
- [ ] Ensure no copyrighted Monty Python audio
- [ ] All quotes are text-to-speech (not clipped audio)

## Phase 2 (Ready While Waiting for Approval)

While Apple reviews your MVP (1-3 weeks), build Phase 2 to ship immediately on approval:

### Phase 2 Features (Priority Order)

1. **Voice Acknowledgment** (medium effort)
   - Tap notification → app listens for "yes"
   - SpeechRecognition to detect voice
   - Confirmation: "Acknowledged" spoken back
   - Don't require this in MVP (some users won't grant mic permission)

2. **News Headlines** (medium effort)
   - Fetch Fox News RSS (no API key needed)
   - Parse `<title>` tags
   - After voice acknowledgment, read top 3 headlines
   - Falls back gracefully if network unavailable

3. **Weather** (medium effort)
   - Use wttr.in API (free, no key required)
   - Request location permission (optional)
   - Read weather after headlines
   - Example: "Today's weather is partly cloudy, high 72 degrees"

4. **Phrase Pool Expansion** (low effort)
   - Optional Claude API integration (user provides API key)
   - Generate new phrases in background (1/week)
   - Expand pool over time
   - Graceful fallback if API unavailable

5. **UI Polish** (low effort)
   - Dark mode support
   - Better spacing/fonts
   - Loading states
   - Animations

### Phase 2 Deployment Strategy

**Goal:** Ship v1.1 within 24 hours of v1.0 approval

**Preparation:**
- Branch: `phase-2-ready` (already built, tested, waiting)
- All code reviewed and tested
- Screenshots/description updated for App Store
- Submission ready to go

**Timeline:**
- Day 0: MVP submitted to App Store
- Days 1-21: Work on Phase 2 (in branch)
- Day 21 (or whenever approved): MVP approved
- Day 22: Merge Phase 2, submit v1.1
- Day 39 (or whenever): v1.1 approved, full feature set live

### Why Phase 2 in Parallel?

- ✅ No wasted time waiting for approval
- ✅ MVP stays small and approvable
- ✅ Phase 2 uses same open-source libraries (wttr.in, RSS)
- ✅ Users get full feature set within 2-3 weeks
- ✅ You learn from MVP feedback while building Phase 2
- ✅ Can do final polish while in review queue

## MVP Success Metrics

### Before Submission
- [ ] Builds without errors in Xcode
- [ ] Runs on real iPhone (not just simulator)
- [ ] App doesn't crash
- [ ] Notifications work at scheduled times
- [ ] Voice alerts play
- [ ] All reminders persist

### After Approval
- [ ] Available on App Store
- [ ] Users can download and install
- [ ] At least 10 test downloads
- [ ] No crash reports in first 24 hours

### Phase 2 Goal
- [ ] Approved within 2 weeks of v1.1 submission
- [ ] Full feature set shipped before end of month

## Testing Plan

### Device Testing (Required)
```bash
# Test on real iPhone 14+ with iOS 16+
1. Build from Xcode
2. Install on device
3. Test each reminder time (or force trigger)
4. Verify voice alert sounds
5. Test settings persist
6. Force-close app, reopen, verify still there
7. Try accessibility (VoiceOver)
```

### TestFlight Testing (Before App Store)
```
1. Archive build in Xcode
2. Upload to TestFlight
3. Invite 10-20 beta testers (friends, family)
4. Gather feedback for 1 week
5. Fix any issues
6. Final build for App Store
```

### Approval Timeline
- Day 0: Submit to App Store
- Day 1-3: Initial review (often fastest)
- Day 3-7: Possible rejection or approval
- Day 7+: Resubmit if needed (usually approved on retry)

## Open Source Considerations

### License: Apache 2.0 (Recommended)
- ✅ Allows commercial use
- ✅ Requires attribution
- ✅ Patent protection
- ✅ Clear liability terms
- Alternative: MIT (simpler, less protection)

### Code Release
- [ ] Clean up any debug code
- [ ] Remove any placeholder API keys
- [ ] Add LICENSE file
- [ ] Add CONTRIBUTING.md
- [ ] Add README for building

### Community
- Consider: GitHub Discussions for user issues
- Consider: Open issues for feature requests
- Consider: Accept pull requests from community

## Success Criteria for MVP

✅ **Code Quality:**
- Compiles without errors or warnings
- No hardcoded values or debug code
- Proper error handling
- Clear variable/function names

✅ **Privacy:**
- Zero external data transmission
- All data on device only
- Privacy policy published
- No tracking or analytics

✅ **UX:**
- Simple, intuitive interface
- No configuration needed (defaults work)
- Quick to set up (< 2 minutes)
- Voice alerts sound good

✅ **Approval:**
- Meets App Store guidelines
- No prohibited content
- Clear purpose and value
- Professional presentation

## Notes

- **Default behavior should work:** User shouldn't need to configure anything to get value
- **Offline-first:** Every feature must work without internet
- **No surprises:** If a permission is requested, it's used (or don't request it)
- **Voice quality:** Test voice synthesis thoroughly - this is the main feature
- **Monty Python:** No copyrighted audio, only text-to-speech of quotes

---

**Next Step:** Review this MVP with Xcode open and decide which existing code to keep vs. simplify. Then assign the small tasks (voice test, UI polish) before TestFlight.
