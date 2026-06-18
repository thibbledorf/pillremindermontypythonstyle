# Pill Reminder - Features & Roadmap

## 🎯 Project Vision
A free, open-source, privacy-first medication reminder with Monty Python humor. Works offline, no data leaves your device.

---

## ✅ Phase 1: iOS MVP (Current - TestFlight/App Store)

### Core Features
- [x] Medication reminders at 4 fixed times (7 AM, 1 PM, 5 PM, 9 PM)
- [x] Voice alerts with AVSpeechSynthesizer (free, built-in TTS)
- [x] 40+ Monty Python phrases in database
- [x] Test Voice button to preview alerts
- [x] Settings tab with privacy notice
- [x] All data stored locally (UserDefaults)
- [x] GitHub link in settings
- [x] Apache 2.0 license

### Completed Infrastructure
- [x] Xcode project (iOS 16+)
- [x] SwiftUI UI with tab navigation
- [x] ReminderManager state management
- [x] UserNotifications integration
- [x] SpeechSynthesizer service
- [x] Comprehensive documentation (ARCHITECTURE.md, DEVELOPMENT.md, etc.)
- [x] App Store submission guide
- [x] GitHub repo public with proper license

### Known Limitations (by design)
- No customizable reminder times (only 4 fixed)
- No voice acknowledgment (Phase 2)
- No news/weather (Phase 2)
- No AI phrase generation (Phase 2)
- No multi-device sync (Phase 4)

---

## 🔄 Phase 2: Enhanced Features (While v1.0 in App Store Review)

**Timeline:** Develop in parallel during 1-3 week approval process

### Voice Acknowledgment
- [ ] Listen for speech for ~20 seconds after notification
- [ ] Detect "yes", "yeah", "done", "OK" variations
- [ ] Speak confirmation: "Acknowledged, you took your medication"
- [ ] Graceful fallback if mic permission denied
- [ ] Timeout handling (silence = acknowledged)

### News Headlines
- [ ] Fetch Fox News RSS (free, no API)
- [ ] Parse top 3 headlines
- [ ] Speak headlines after acknowledgment
- [ ] Cache headlines locally
- [ ] Fallback if network unavailable
- [ ] Timeout after 10 seconds

### Weather Reports
- [ ] Request location permission (optional)
- [ ] Call wttr.in API (free, no auth)
- [ ] Get local weather summary
- [ ] Speak weather: "Partly cloudy, high 72 degrees"
- [ ] Graceful fallback if location denied
- [ ] Cache last known weather

### AI Phrase Generation
- [ ] Optional API key field in settings
- [ ] Integrate Anthropic API (claude-haiku-4-5)
- [ ] Generate 1 new phrase weekly
- [ ] Store in PhraseCache
- [ ] Fall back to built-in if API unavailable
- [ ] Handle rate limiting gracefully

### UI Polish
- [ ] Dark mode support
- [ ] Smooth animations
- [ ] Loading states for async operations
- [ ] Better typography and spacing
- [ ] VoiceOver accessibility testing
- [ ] Dynamic type support

### Version 1.1 Changes
- [ ] Update app description for App Store
- [ ] New screenshots showing voice feature
- [ ] Bump version to 1.1.0
- [ ] Submit within 24 hours of v1.0 approval

---

## 🖥️ Phase 3: Multi-Platform Support

### macOS (SwiftUI, iOS code reuse)
- [ ] Reuse Swift models and VoiceManager
- [ ] Create macOS-specific UI (window-based)
- [ ] Menu bar app option
- [ ] iCloud sync optional
- [ ] Target: Mac App Store
- [ ] Timeline: Weeks 5-6

### Windows (C# + MAUI)
- [ ] Reimplement models in C#
- [ ] Use System.Speech for TTS
- [ ] MAUI for cross-platform UI
- [ ] File-based storage (JSON)
- [ ] Windows Notification system
- [ ] Target: Microsoft Store (optional)
- [ ] Timeline: Weeks 7-9

### Linux (Python + PyQt6)
- [ ] Implement models in Python
- [ ] Use pyttsx3 or espeak for TTS
- [ ] PyQt6 for UI
- [ ] JSON or SQLite storage
- [ ] D-Bus notifications
- [ ] Distribution: Direct download, package managers
- [ ] Timeline: Weeks 9-10

---

## ☁️ Phase 4: Cloud Sync & Authentication

### Backend (Node.js/Express)
- [ ] User authentication (OAuth or email/password)
- [ ] Reminder CRUD API
- [ ] Sync endpoint (delta sync)
- [ ] Database (PostgreSQL or MongoDB)
- [ ] HTTPS only
- [ ] Rate limiting

### Client Features (All Platforms)
- [ ] Optional login flow
- [ ] Bi-directional sync
- [ ] Offline-first (local works without internet)
- [ ] Conflict resolution
- [ ] Account deletion
- [ ] Data export

### Timeline: Weeks 11+

---

## 📋 Tech Debt & Known Issues

### iOS
- [ ] Simplify ReminderManager (remove Phase 2 code)
- [ ] Add unit tests for voice manager
- [ ] Improve error handling in services
- [ ] Code comments for complex logic
- [ ] Accessibility audit (VoiceOver, contrast, fonts)

### General
- [ ] Create CONTRIBUTING.md with examples
- [ ] Add GitHub Actions CI/CD
- [ ] Set up issue templates properly
- [ ] Create good first issue labels
- [ ] Build contributor onboarding docs

---

## 🎯 Milestones

### Q1 2026 (Now)
- [x] iOS MVP built & documented
- [x] Apache 2.0 license chosen
- [x] GitHub public + ready to submit
- [ ] **TARGET:** App Store submission (late June)

### Q2 2026
- [ ] v1.0 App Store approval (1-3 weeks after submission)
- [ ] v1.1 with Phase 2 features released (within 24 hours of v1.0 approval)
- [ ] macOS version launched
- [ ] Community feedback incorporated

### Q3 2026
- [ ] Windows version launched
- [ ] Linux version launched
- [ ] Backend infrastructure started

### Q4 2026
- [ ] Cloud sync available
- [ ] Multi-device sync working
- [ ] 1.0+ users

---

## 🚀 Quick Reference: What to Build Next

### Immediate (This Week)
1. ✅ iOS MVP finished
2. ✅ License sorted (Apache 2.0)
3. [ ] Create privacy policy
4. [ ] Take App Store screenshots
5. [ ] Submit to TestFlight for beta testing

### After TestFlight (1 week)
1. [ ] Submit to App Store
2. [ ] Start Phase 2 branch (`phase-2-ready`)

### While in App Store Review (1-3 weeks)
1. [ ] Build voice acknowledgment
2. [ ] Build news fetching
3. [ ] Build weather fetching
4. [ ] Add AI phrase generation
5. [ ] Polish UI (dark mode, animations)
6. [ ] Update screenshots
7. [ ] Test everything thoroughly

### Day of v1.0 Approval
1. [ ] Merge Phase 2 to main
2. [ ] Bump version to 1.1.0
3. [ ] Submit Phase 2 to App Store
4. [ ] Celebrate! 🎉

---

## 🎭 Voice Alert Examples (by phase)

### Phase 1: Voice Only
```
"Take your [Condition] medication! [Monty Python Quote]"
Example: "Take your Parkinsons medication! Nudge nudge, wink wink, say no more!"
```

### Phase 2: Voice + News + Weather
```
"Take your [Condition] medication! [Quote]. You have [Condition].
[Pause]
Top news: [Headline 1]. [Headline 2]. [Headline 3].
[Pause]
Weather: [Current conditions]."

Example: "Take your Parkinsons medication! It's just a flesh wound! You have Parkinsons.
Top news: Tech stocks rally. Scientists discover new protein. Politics update.
Weather: Partly cloudy, high 72 degrees, light breeze."
```

---

## 📊 Platform Support Matrix

| Feature | iOS | macOS | Windows | Linux | Web |
|---------|-----|-------|---------|-------|-----|
| Reminders | ✅ v1.0 | 🔄 v2.0 | 🔄 v3.0 | 🔄 v3.0 | ❓ |
| Voice | ✅ v1.0 | 🔄 v2.0 | 🔄 v3.0 | 🔄 v3.0 | ❓ |
| News | 🔄 v1.1 | 🔄 v2.1 | 🔄 v3.1 | 🔄 v3.1 | ❓ |
| Weather | 🔄 v1.1 | 🔄 v2.1 | 🔄 v3.1 | 🔄 v3.1 | ❓ |
| AI Phrases | 🔄 v1.1 | 🔄 v2.1 | 🔄 v3.1 | 🔄 v3.1 | ❓ |
| Cloud Sync | ⏳ v4.0 | ⏳ v4.0 | ⏳ v4.0 | ⏳ v4.0 | ❓ |
| Multi-device | ⏳ v4.0 | ⏳ v4.0 | ⏳ v4.0 | ⏳ v4.0 | ❓ |

**Legend:** ✅ Done | 🔄 In Progress/Planned | ⏳ Future | ❓ TBD

---

## 🎁 Nice-to-Have Features (Future Consideration)

- Custom reminder times (instead of fixed 4)
- Multiple reminder profiles ("work", "home", "travel")
- Medication history tracking
- Health app integration (iOS)
- Calendar integration
- Voice customization (pitch, rate)
- Monty Python audio clips (licensed)
- Localization (other languages)
- Dark mode (Phase 2+)
- Watch app (Phase 3+)
- Siri shortcuts (Phase 3+)
- Home Kit integration
- HealthKit integration
- iCloud backup (Phase 4+)

---

## 🐛 Known Issues & Workarounds

### Phase 1 (Current)
| Issue | Status | Workaround |
|-------|--------|-----------|
| Simulator notifications limited | Known | Test on real device |
| Voice test doesn't play on mute | By design | Unmute device |
| Times can't be customized | By design | Phase 2+ feature |
| No news/weather | By design | Phase 2 feature |

---

## 📞 Support & Community

- **GitHub Issues:** Bug reports, feature requests
- **GitHub Discussions:** General questions
- **Contributing:** See CONTRIBUTING.md
- **Security:** Report privately (no public issues)

---

**Last Updated:** June 17, 2026  
**Current Phase:** Phase 1 MVP Complete  
**Next Milestone:** App Store Submission
