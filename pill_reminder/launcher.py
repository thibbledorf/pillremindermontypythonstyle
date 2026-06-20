#!/usr/bin/env python3
"""
Pill Reminder Launcher
• Runs pill_reminder.py as a managed subprocess
• Watchdog: auto-restarts if it crashes
• Detects config.json changes and restarts with new settings
• System tray icon with Settings / Trigger / Restart / Exit menu
"""

import os
import sys
import subprocess
import threading
import time
import json

import pystray
from PIL import Image, ImageDraw

SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
REMINDER_PY  = os.path.join(SCRIPT_DIR, "pill_reminder.py")
SETTINGS_PY  = os.path.join(SCRIPT_DIR, "settings_ui.py")
CONFIG_FILE  = os.path.join(SCRIPT_DIR, "config.json")
AGENT_PORT   = 5000

_stop_event      = threading.Event()
_restart_event   = threading.Event()
_proc: subprocess.Popen | None = None
_proc_lock       = threading.Lock()


# ─── Tray icon ────────────────────────────────────────────────────────────────

def _make_icon() -> Image.Image:
    """Draw a simple pill icon programmatically (no image file needed)."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Pill body
    d.rounded_rectangle([4, 20, 60, 44], radius=12, fill=(60, 140, 255))
    # Centre dividing line
    d.line([32, 20, 32, 44], fill=(255, 255, 255, 200), width=2)
    # Right half slightly lighter
    d.rounded_rectangle([32, 20, 60, 44], radius=12, fill=(120, 200, 255))
    d.line([32, 20, 32, 44], fill=(255, 255, 255, 200), width=2)
    return img


def _open_settings(icon, item):
    result = subprocess.run([sys.executable, SETTINGS_PY], cwd=SCRIPT_DIR)
    if result.returncode == 0:
        # Config was saved — restart the reminder
        _restart_event.set()


def _trigger_now(icon, item):
    try:
        import requests as _req
        _req.post(f"http://localhost:{AGENT_PORT}/trigger", timeout=3)
    except Exception as exc:
        print(f"Trigger failed: {exc}")


def _restart_reminder(icon, item):
    _restart_event.set()


def _exit_app(icon, item):
    _stop_event.set()
    _kill_proc()
    icon.stop()


def _build_menu():
    return pystray.Menu(
        pystray.MenuItem("Pill Reminder ✅", None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Settings…",      _open_settings),
        pystray.MenuItem("Trigger now",    _trigger_now),
        pystray.MenuItem("Restart",        _restart_reminder),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Exit",           _exit_app),
    )


# ─── Process management ───────────────────────────────────────────────────────

def _kill_proc():
    global _proc
    with _proc_lock:
        if _proc and _proc.poll() is None:
            _proc.terminate()
            try:
                _proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                _proc.kill()
        _proc = None


def _start_proc():
    global _proc
    with _proc_lock:
        _proc = subprocess.Popen(
            [sys.executable, REMINDER_PY],
            cwd=SCRIPT_DIR,
        )
    print(f"[launcher] Started pill_reminder.py (PID {_proc.pid})")


def _watchdog():
    """Runs in background — starts the reminder and restarts it on crash or
    config change."""
    config_mtime = _config_mtime()

    while not _stop_event.is_set():
        _start_proc()
        _restart_event.clear()

        while not _stop_event.is_set() and not _restart_event.is_set():
            # Check if process died
            with _proc_lock:
                dead = _proc is None or _proc.poll() is not None
            if dead:
                print("[launcher] pill_reminder.py exited — restarting in 3 s…")
                time.sleep(3)
                break

            # Check if config changed
            new_mtime = _config_mtime()
            if new_mtime != config_mtime:
                config_mtime = new_mtime
                print("[launcher] Config changed — restarting pill_reminder.py…")
                _restart_event.set()
                break

            time.sleep(2)

        if not _stop_event.is_set():
            _kill_proc()
            if _restart_event.is_set():
                time.sleep(1)   # brief pause so the port clears


def _config_mtime() -> float:
    try:
        return os.path.getmtime(CONFIG_FILE)
    except OSError:
        return 0.0


# ─── Entry point ──────────────────────────────────────────────────────────────

def main():
    # Start watchdog thread
    t = threading.Thread(target=_watchdog, daemon=True)
    t.start()

    # System tray (blocks until Exit is chosen)
    icon = pystray.Icon(
        "pill_reminder",
        _make_icon(),
        "Pill Reminder",
        _build_menu(),
    )
    icon.run()

    # Cleanup after tray exits
    _stop_event.set()
    _kill_proc()


if __name__ == "__main__":
    main()
