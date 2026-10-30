# Pill Reminder — macOS

Native Swift menu-bar app. It runs as a per-user LaunchAgent, starts at login, and
relaunches on any exit. A second LaunchAgent probes its health every 5 minutes.

## Build

Requires only the Xcode Command Line Tools (no full Xcode).

```bash
zsh macos/build.sh
```

Output: `macos/dist/PillReminder-1.0.0.pkg`

## Install

Double-click the `.pkg`, or:

```bash
sudo installer -pkg macos/dist/PillReminder-1.0.0.pkg -target /
```

The installer puts `Pill Reminder.app` in `/Applications`, installs both LaunchAgents
for the logged-in user, and starts the app. On first start macOS asks for Microphone,
Speech Recognition and Notifications. Microphone and Speech Recognition are needed
only for the spoken "yes".

The app is ad-hoc signed (no Developer ID). A `.pkg` built on this Mac installs
without a Gatekeeper prompt. On another Mac, right-click the `.pkg` and choose Open.

## Uninstall

```bash
sudo zsh "/Applications/Pill Reminder.app/Contents/Resources/uninstall.sh"
```

Add `--purge` to also delete settings, the phrase cache, logs and the API key.

## Files

| What | Where |
|---|---|
| Settings | `~/Library/Application Support/PillReminder/config.json` |
| AI phrase cache | `~/Library/Application Support/PillReminder/generated_phrases.json` |
| Cache health | `~/Library/Application Support/PillReminder/cache_status.json` |
| Dose state | `~/Library/Application Support/PillReminder/state.json` |
| Log | `~/Library/Logs/PillReminder/pill_reminder.log` |
| Health-check log | `~/Library/Logs/PillReminder/healthcheck.log` |
| API key | Keychain, service `PillReminderMontyPython` |

Edits to `config.json` take effect on the next 5-second tick. No restart is needed.

## Acknowledging a reminder

Any of these works: the big green button, Return or Space, saying "yes", the
notification's "I took them" action, the menu-bar item, or `POST /acknowledge`.

## Local API (127.0.0.1:5055)

Port 5000, which the Windows build uses, belongs to the macOS AirPlay Receiver.

| Endpoint | Purpose |
|---|---|
| `GET /health` | 200 if the scheduler, reminder cycle and main thread are all live; 503 with the reason if not |
| `GET /status` | Active reminder, last fire, last acknowledgment and its source |
| `GET /next` | Next dose and the minutes until it |
| `GET /cache` | Phrase-cache count, last success, last error, key source |
| `POST /acknowledge` | Acknowledge the active reminder |
| `POST /trigger` | Fire a test reminder |
| `POST /cache/refill` | Generate 3 new phrases now |

## Fixes for the two Windows bugs

### "Cache of responses not updating"

Root causes in the Windows code:

- The C# service has no AI phrase generation at all.
- The Python version reads the key only from `ANTHROPIC_API_KEY`, which Task Scheduler
  never sets.
- It tries only on a 20% coin flip.
- It swallows every error.
- Its 35+ built-in phrases drown out the few generated ones, so new phrases are rarely heard.

What the macOS build does instead:

- Reads the API key from the Keychain (entered in Settings), with the env var as a fallback.
- Generates 2 new phrases after every acknowledged reminder, and 1–5 at startup.
- Logs every failure with its HTTP status, and shows it in `GET /cache` and in the menu.
- Gives AI phrases a 60% share of picks (`ai_phrase_share`), least-used first.
- Writes the cache atomically, removes duplicates, and caps it at 200 (oldest dropped).
- Puts the configured condition into the prompt instead of hard-coding it.

### "Service going silent but not dead"

Root causes in the Windows code:

- SAPI `Speak()` and the recognizer have no timeout. One hang holds the cycle lock
  forever, so every later reminder logs "already running — skipping" while the process
  still looks alive.
- A slot is marked fired before it is acknowledged, so a crash mid-reminder loses that dose.

What the macOS build does instead:

- **Hard deadlines on every blocking step.** Speech runs as a `say` child process that is
  killed if it overruns. Listening, HTTP and AppleScript calls are all bounded.
- **Heartbeats plus an in-process watchdog** on its own OS thread. If the scheduler stalls
  for 90 s, the reminder cycle for 240 s, or the main thread for 120 s, the app logs the
  reason and exits. launchd `KeepAlive` relaunches it.
- **External health check** every 5 minutes. Three failed `/health` probes trigger
  `launchctl kickstart -k`, which covers a fully wedged process.
- **A dose is recorded only when acknowledged or given up.** A crash or restart mid-reminder
  re-fires it. This was verified by `kill -9` during a reminder.
- **Catch-up window instead of exact-minute matching.** Sleep, restarts and slow ticks can't
  skip a dose. Reminders fire up to `catch_up_minutes` (180) late, and the log says how late.
- **App Nap disabled**, and the agent runs as `ProcessType Interactive`, so macOS doesn't
  throttle the timer.
- **Mute guard.** Before each reminder the app unmutes the Mac and raises the volume to
  `min_volume` (50). Set it to 0 to disable.
- **Not voice-only.** An always-on-top panel with a large button and a lock-screen
  notification appear alongside the speech.
- **Gives up after `give_up_minutes` (90)** with a "NOT acknowledged" notification, instead
  of nagging forever.
