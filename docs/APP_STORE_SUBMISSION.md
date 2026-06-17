# App Store Submission Guide

This guide covers submitting Pill Reminder to the Apple App Store (iOS) and Mac App Store (macOS).

## Prerequisites

1. **Apple Developer Account**
   - Individual: $99/year
   - Enroll at [developer.apple.com](https://developer.apple.com)
   - Takes 1-2 days for approval

2. **Requirements**
   - App built with Xcode 14+
   - iOS 14 or later (minimum deployment target)
   - All requirements met on your Mac dev machine

3. **Signing Certificates**
   - Xcode handles this with Automatic Signing
   - Must enable in Xcode (Signing & Capabilities tab)

## Pre-Submission Checklist

### Code & Testing
- [ ] All unit tests pass
- [ ] No SwiftLint warnings
- [ ] App tested on real device (not just simulator)
- [ ] No hardcoded API keys or credentials
- [ ] All features documented and working
- [ ] Crash logs reviewed (Xcode Organizer)

### App Content
- [ ] Privacy policy written (required)
- [ ] Screenshots captured (min 2, max 5)
- [ ] App preview video created (optional, ~30 sec)
- [ ] App icon finalized (1024x1024 pixels)
- [ ] Localized if supporting multiple languages

### Configuration
- [ ] Version bumped in Xcode (e.g., 1.0.0)
- [ ] Build number incremented
- [ ] Bundle ID correct (e.g., com.yourname.pillreminder)
- [ ] App category selected: "Health & Fitness" or "Lifestyle"

### Legal
- [ ] Privacy policy uploaded/linked
- [ ] Terms of Service (if applicable)
- [ ] IDFA declaration: "This app does not use IDFA"
- [ ] Encryption: If using HTTPS, verify compliance
- [ ] Age rating questionnaire completed (typically 4+)

## Step-by-Step Submission (iOS)

### 1. Create App Store Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click "My Apps" → "+"
3. Select "New App"
4. Fill in:
   - **Platform:** iOS
   - **App Name:** "Pill Reminder"
   - **Primary Language:** English
   - **Bundle ID:** Select existing or create new
   - **SKU:** "PillReminder01" (unique identifier)
   - **User Access:** Full access

### 2. Prepare Screenshots & Media

In App Store Connect → Your App → "App Store" tab:

**Screenshots (minimum 2, maximum 5):**
- iPhone: 6.5-inch (1242×2688 px) or 5.5-inch (1242×2208 px)
- Recommended: Show main list, add reminder, settings screens
- Can add text overlays in Xcode or Preview app

**Preview Video (optional but recommended):**
- ~30 seconds long
- MP4 format, max 500MB
- Show app in action: adding reminder, voice test, settings

**App Icon:**
- 1024×1024 pixels
- Format: PNG or JPG
- No rounded corners (App Store handles this)

### 3. Fill App Information

**Name & Subtitle:**
- Name: "Pill Reminder"
- Subtitle: "Monty Python's Medication Reminder"

**Description:**
```
Never miss your medication with a comedic reminder!

Pill Reminder combines medication management with Monty Python 
humor. Get witty voice alerts that mention your condition and 
optionally read you weather and news.

Features:
• Customizable reminders with time and day selection
• Voice alerts with condition-specific messages
• Optional weather and news in alerts
• Adjustable voice rate and volume
• Beautiful, simple interface
• Works completely offline
```

**Keywords:**
Pill reminder, medication reminder, health, pharmacy, monty python, voice alerts, medication tracker

**Support URL:**
Link to your GitHub repository or support page

**Privacy Policy URL:**
Must be a valid URL (can be GitHub wiki or external site)

### 4. Set App Category

- **Primary Category:** Health & Fitness or Lifestyle
- **Secondary Category:** Optional

### 5. Ratings & Restrictions

**Age Rating Questionnaire:**
1. Click "Age Ratings"
2. Answer questions about content (violence, language, etc.)
3. For Pill Reminder: should result in 4+ rating
4. Save ratings

**Restrictions:**
- Unrestricted for all regions (unless applicable)

### 6. Privacy & Data

**Privacy Policy:**
- Must explain what data you collect
- For Pill Reminder Phase 1 (local-only): 
  ```
  Pill Reminder stores all data locally on your device. 
  No personal information is collected or transmitted. 
  The app does not use cookies or tracking. 
  ```

**Data & Privacy:**
1. Click "Privacy"
2. Indicate what data is collected:
   - Health: "Medication information" (reminders)
   - If using location for weather: add Location data
3. Answer "Is this app required to use Apple's Sign in with Apple?"
   - No (unless you add cloud sync in Phase 2)

**IDFA Declaration:**
- Click "App Privacy"
- "Does your app use Advertising ID (IDFA)?" → No

### 7. Build & Upload

**In Xcode:**
1. Select "PillReminder" target
2. Select "Generic iOS Device" scheme
3. Product → Archive
4. Xcode Organizer opens → Validate App
5. Click "Distribute App"
6. Select "App Store Connect"
7. Choose signing method (Automatic recommended)
8. Upload to App Store Connect

**Alternative (command line):**
```bash
xcodebuild -scheme PillReminder -configuration Release \
  -derivedDataPath build archive \
  -archivePath build/PillReminder.xcarchive

# Then upload via Xcode Organizer or xcrun
xcrun altool --upload-app --file PillReminder.ipa \
  --type ios --apiKey [API_KEY] --apiIssuer [ISSUER_ID]
```

### 8. Submit for Review

1. Go to App Store Connect → Your App → "App Store" tab
2. Scroll to "Build"
3. Select the build you just uploaded
4. Click "Submit for Review"
5. Accept agreements
6. Click "Submit"

**Review Time:** Typically 1-3 days, sometimes up to 1-2 weeks

## After Submission

### While in Review
- App shows "Waiting for Review" status
- Cannot make changes to this submission
- You can prepare version 2.0 if needed

### If Rejected
1. Read rejection details carefully
2. Common reasons for Pill Reminder:
   - Incomplete privacy policy
   - Missing keywords/description
   - Accessibility issues
   - Unclear purpose of permissions
3. Fix issues, increment build number, re-upload
4. Resubmit for review

### If Approved
- App appears on App Store within hours
- You receive approval email
- Mark your GitHub release as "Shipped"

## macOS (Mac App Store)

Process is nearly identical to iOS:

1. In Xcode, select macOS target instead of iOS
2. Archive → Validate → Distribute
3. In App Store Connect, create new macOS app
4. Upload and submit same way

**Differences:**
- Screenshots: 1280×800 px minimum
- Installer support: If needed, create .pkg installer
- Notarization: Apple automatically notarizes your app

## Testing Before Submission

### TestFlight (Recommended)

1. In App Store Connect → "TestFlight"
2. Add internal testers (Apple ID emails)
3. Build → submit to TestFlight
4. Testers download via TestFlight app
5. Get feedback before official submission

**Setup:**
1. Add beta testers: "Internal Testing" section
2. Upload build
3. Wait for processing (usually <30 minutes)
4. Testers get email, download app via TestFlight

### Local Testing
```bash
# Test on device or simulator one last time
xcodebuild -scheme PillReminder -configuration Release test
```

## Version Updates

**For future updates:**
1. Increment version in Xcode (1.0.0 → 1.0.1)
2. Update CHANGELOG.md
3. Commit and tag: `git tag v1.0.1`
4. Archive and upload new build
5. Update description/screenshots if changed
6. Resubmit

**Version numbering:**
- Major.Minor.Patch (1.0.0)
- Major: large feature adds
- Minor: new features
- Patch: bug fixes

## Common Rejection Reasons

| Reason | Solution |
|--------|----------|
| "Incomplete privacy policy" | Add URL to actual privacy policy doc |
| "Metadata does not match app" | Ensure description matches actual features |
| "Missing permissions explanation" | Explain why you need any special permissions |
| "Crash on launch" | Test on real device, check console logs |
| "Accessibility issues" | Enable accessibility inspector, fix contrast/labels |
| "Unclear functionality" | Add more detailed description and screenshots |

## Helpful Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode/)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

## Notes for Pill Reminder

- Ensure notification permissions properly requested at runtime
- Test voice alerts work at specified time
- Verify no health data leaks in console logs
- Consider accessibility: screen reader support for all UI

Good luck with your submission! 🎭
