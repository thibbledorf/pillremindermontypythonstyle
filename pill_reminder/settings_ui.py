#!/usr/bin/env python3
"""Settings GUI for Pill Reminder — Monty Python Edition."""

import json
import os
import sys
import customtkinter as ctk

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "config.json")
DEFAULTS = {
    "pill_times":   ["07:00", "13:00", "17:00", "21:00"],
    "malady":       "Parkinson's",
    "voice_gender": "male",
    "voice_accent": "british",
}


def load_config() -> dict:
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return {**DEFAULTS, **json.load(f)}
    except Exception:
        return dict(DEFAULTS)


def save_config(cfg: dict):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)


class SettingsApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Pill Reminder — Settings")
        self.geometry("480x560")
        self.resizable(False, False)
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        self._cfg = load_config()
        self._time_entries: list[ctk.CTkEntry] = []
        self._build_ui()

    def _build_ui(self):
        pad = {"padx": 20, "pady": 6}

        # ── Header ──────────────────────────────────────────────────────────
        ctk.CTkLabel(
            self, text="🧪 Pill Reminder Settings",
            font=ctk.CTkFont(size=20, weight="bold"),
        ).pack(pady=(20, 4))
        ctk.CTkLabel(
            self, text="Monty Python Edition",
            font=ctk.CTkFont(size=13), text_color="gray",
        ).pack(pady=(0, 14))

        # ── Number of reminders per day ─────────────────────────────────────
        ctk.CTkLabel(self, text="Reminders per day", anchor="w").pack(fill="x", **pad)
        self._count_var = ctk.IntVar(value=len(self._cfg["pill_times"]))
        count_frame = ctk.CTkFrame(self, fg_color="transparent")
        count_frame.pack(fill="x", padx=20, pady=2)
        self._count_label = ctk.CTkLabel(count_frame, text=str(self._count_var.get()), width=28)
        self._count_label.pack(side="right")
        ctk.CTkSlider(
            count_frame, from_=1, to=6, number_of_steps=5,
            variable=self._count_var, command=self._on_count_change,
        ).pack(side="left", fill="x", expand=True, padx=(0, 8))

        # ── Time entries (dynamic) ───────────────────────────────────────────
        ctk.CTkLabel(self, text="Reminder times (HH:MM, 24-hour)", anchor="w").pack(fill="x", **pad)
        self._times_frame = ctk.CTkFrame(self)
        self._times_frame.pack(fill="x", padx=20, pady=4)
        self._rebuild_time_entries(self._cfg["pill_times"])

        # ── Malady ──────────────────────────────────────────────────────────
        ctk.CTkLabel(self, text="Condition / malady (used in reminders)", anchor="w").pack(fill="x", **pad)
        self._malady_var = ctk.StringVar(value=self._cfg.get("malady", "Parkinson's"))
        ctk.CTkEntry(self, textvariable=self._malady_var).pack(fill="x", **pad)

        # ── Voice gender ────────────────────────────────────────────────────
        ctk.CTkLabel(self, text="Voice gender", anchor="w").pack(fill="x", **pad)
        self._gender_var = ctk.StringVar(value=self._cfg.get("voice_gender", "male"))
        gender_frame = ctk.CTkFrame(self, fg_color="transparent")
        gender_frame.pack(fill="x", padx=20, pady=2)
        for val, label in [("male", "Male"), ("female", "Female")]:
            ctk.CTkRadioButton(gender_frame, text=label, variable=self._gender_var, value=val).pack(side="left", padx=12)

        # ── Voice accent ────────────────────────────────────────────────────
        ctk.CTkLabel(self, text="Voice accent", anchor="w").pack(fill="x", **pad)
        self._accent_var = ctk.StringVar(value=self._cfg.get("voice_accent", "british"))
        accent_frame = ctk.CTkFrame(self, fg_color="transparent")
        accent_frame.pack(fill="x", padx=20, pady=2)
        for val, label in [("british", "British"), ("american", "American")]:
            ctk.CTkRadioButton(accent_frame, text=label, variable=self._accent_var, value=val).pack(side="left", padx=12)

        # ── Buttons ─────────────────────────────────────────────────────────
        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=20, pady=20)
        ctk.CTkButton(btn_frame, text="Cancel", fg_color="gray40", command=self._cancel).pack(side="left", expand=True, padx=4)
        ctk.CTkButton(btn_frame, text="Save & Apply", command=self._save).pack(side="right", expand=True, padx=4)

    def _on_count_change(self, val):
        n = int(round(float(val)))
        self._count_var.set(n)
        self._count_label.configure(text=str(n))
        current_times = [e.get().strip() or "08:00" for e in self._time_entries]
        # Pad or trim to match new count
        while len(current_times) < n:
            current_times.append("08:00")
        current_times = current_times[:n]
        self._rebuild_time_entries(current_times)

    def _rebuild_time_entries(self, times: list):
        for w in self._times_frame.winfo_children():
            w.destroy()
        self._time_entries = []
        for i, t in enumerate(times):
            row = ctk.CTkFrame(self._times_frame, fg_color="transparent")
            row.pack(fill="x", pady=2, padx=8)
            ctk.CTkLabel(row, text=f"  {i + 1}.", width=24).pack(side="left")
            entry = ctk.CTkEntry(row, width=90, placeholder_text="HH:MM")
            entry.insert(0, t)
            entry.pack(side="left", padx=6)
            self._time_entries.append(entry)

    def _collect_times(self) -> list[str]:
        times = []
        for e in self._time_entries:
            val = e.get().strip()
            if not val:
                continue
            # Basic normalisation: accept H:MM → 0H:MM
            parts = val.split(":")
            if len(parts) == 2:
                h, m = parts
                val = f"{int(h):02d}:{int(m):02d}"
            times.append(val)
        times.sort()
        return times

    def _save(self):
        cfg = {
            "pill_times":   self._collect_times(),
            "malady":       self._malady_var.get().strip() or "Parkinson's",
            "voice_gender": self._gender_var.get(),
            "voice_accent": self._accent_var.get(),
        }
        save_config(cfg)
        self.destroy()
        sys.exit(0)   # exit code 0 = saved; launcher restarts the reminder

    def _cancel(self):
        self.destroy()
        sys.exit(1)   # exit code 1 = cancelled; launcher does nothing


if __name__ == "__main__":
    app = SettingsApp()
    app.mainloop()
