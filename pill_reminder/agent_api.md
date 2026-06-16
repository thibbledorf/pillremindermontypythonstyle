# Pill Reminder — Agent API Reference

The reminder exposes a small HTTP API on **http://localhost:5000** so other agents
can interact with it without requiring any physical input from you.

---

## Endpoints

### `GET /status`
Returns whether a reminder is currently active and all scheduled times.

```json
{
  "reminder_active": false,
  "pill_times": ["07:00", "13:00", "17:00", "21:00"],
  "current_time": "13:42"
}
```

---

### `POST /acknowledge`
Tells the reminder the pills have been taken. If a reminder is active, it stops
the alarm and triggers the Fox News + weather readout.

```json
{ "status": "acknowledged" }
```
or if no reminder was firing:
```json
{ "status": "no_active_reminder" }
```

---

### `POST /trigger`
Manually fire a reminder right now (useful for testing, or if an agent detects
the user has just woken up and needs a prompt).

```json
{ "status": "triggered" }
```

---

### `GET /next`
Returns how many minutes until each upcoming reminder.

```json
{
  "next": { "time": "17:00", "minutes_until": 78 },
  "all": [
    { "time": "17:00", "minutes_until": 78 },
    { "time": "21:00", "minutes_until": 318 },
    { "time": "07:00", "minutes_until": 1038 },
    { "time": "13:00", "minutes_until": 1278 }
  ]
}
```

---

## Acknowledgment flow

An agent can acknowledge by simply:

```
POST http://localhost:5000/acknowledge
```

No body required. The system will then automatically speak the Fox News headlines
and local weather report through the speakers.
