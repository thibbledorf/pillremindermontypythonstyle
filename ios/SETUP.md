# Pill Reminder — iOS (Monty Python Edition)

Swift/SwiftUI port of the Windows pill reminder. Source files are in
`PillReminder/`, and the Xcode project is `PillReminder.xcodeproj`.

## Platform constraint (read this first)

iOS does **not** allow apps to keep listening on the microphone, or run a
background scheduler, indefinitely the way the Windows script does — Apple
suspends apps and blocks always-on mic access for privacy. So the design is:

- A local notification fires at 07:00 / 13:00 / 17:00 / 21:00 with a **fresh
  Monty Python phrase as the visible notification text** — always varied,
  even if you never open the app.
- Tapping the notification body (or its **"I Took My Pills"** action button)
  opens/foregrounds the app, which then speaks the reminder aloud, listens
  for your spoken "yes" for ~20 seconds, and on acknowledgment speaks the
  Fox headlines + weather — matching the Windows app's behavior.
- iOS caps an app at 64 pending local notifications, so the app keeps a
  rolling 14-day window (4/day = 56 notifications) and tops it off each
  time you open the app.

## Setup steps

1. Open `ios/PillReminder.xcodeproj` in Xcode 16 or later. The project targets
   iOS 17.0, and usage strings are already in `PillReminder/Info.plist`. New
   files added to `PillReminder/` are picked up automatically.
2. Under the target's **Signing & Capabilities** tab, set your Apple
   Developer team (you mentioned you already have a dev account) so it can
   be installed on a real iPhone.
3. Build and run on your iPhone (not just the simulator — the simulator
   can't reliably exercise mic/speech recognition or notifications the same
   way).
4. In the app, go to the **Settings** tab and paste in your Anthropic API
   key (`sk-ant-...`) from console.anthropic.com if you want the AI-generated
   phrase variety. This is optional — the app works fine with just the 40
   static Monty Python phrases if you skip it.

## How phrase variety works

- `Phrases.swift` ships 40 static Monty Python reminder lines (ported
  directly from the Windows app).
- `ClaudeService.swift` calls the Anthropic Messages API directly over
  HTTPS (there's no official Anthropic Swift SDK) using `claude-haiku-4-5`
  to mint new phrases.
- `PhraseCache.swift` saves every generated phrase to a JSON file in the
  app's Documents directory, so the pool only grows — phrases are never
  lost between launches and never repeat until you've heard them all.
- Each time you open the app, there's a 1-in-3 chance it asks Claude for one
  new phrase in the background (keeps the pool fresh without spamming the
  API every launch).

## Notes on the news/weather readout

- Fox News headlines come from the same RSS feeds as the Windows app,
  parsed with a small built-in `XMLParser` (no third-party RSS library
  needed for just pulling `<title>` tags).
- Weather comes from `wttr.in` (no API key needed) using your device's
  current location via CoreLocation.
