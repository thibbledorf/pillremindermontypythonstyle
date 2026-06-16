#!/usr/bin/env python3
"""
Pill Reminder - Monty Python Edition
Medication reminders with voice acknowledgment, Fox News headlines, and local weather.
Agent-callable via HTTP on localhost:5000.
"""

import schedule
import time
import threading
import random
import requests
import feedparser
import pyttsx3
import speech_recognition as sr
from flask import Flask, jsonify, request
import keyboard
from datetime import datetime
import sys
import logging
import os
import io
import wave
import json

try:
    import anthropic as _anthropic_sdk
    _ANTHROPIC_OK = True
except ImportError:
    _ANTHROPIC_SDK = None
    _ANTHROPIC_OK = False

try:
    import sounddevice as sd
    import numpy as np
    _SOUNDDEVICE_OK = True
except ImportError:
    _SOUNDDEVICE_OK = False

try:
    import pyaudio as _pyaudio
    _PYAUDIO_OK = True
except ImportError:
    _PYAUDIO_OK = False

_VOICE_ENABLED = _SOUNDDEVICE_OK or _PYAUDIO_OK

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(os.path.join(os.path.dirname(__file__), "pill_reminder.log")),
    ],
)
log = logging.getLogger(__name__)

# ─── Config ───────────────────────────────────────────────────────────────────
PILL_TIMES        = ["07:00", "13:00", "17:00", "21:00"]
FOX_NEWS_RSS      = "https://moxie.foxnews.com/google-publisher/latest.xml"
FOX_NEWS_RSS_ALT  = "http://feeds.foxnews.com/foxnews/latest"
NEWS_COUNT        = 5
AGENT_PORT        = 5000
REMINDER_INTERVAL = 60   # seconds between repeat reminders if unacknowledged
LISTEN_SECONDS    = 8    # how long to listen for voice each attempt

# ─── Monty Python content ─────────────────────────────────────────────────────
REMINDER_PHRASES = [
    (
        "ALERT! ALERT! The Ministry of Silly Walks has officially declared "
        "it PILL O'CLOCK! I don't care HOW you walk to them, just GET THERE!"
    ),
    (
        "Listen! Strange women lying in ponds distributing swords is no basis "
        "for a health plan — but PILLS ARE! Take them NOW, I command thee!"
    ),
    (
        "TIS BUT A SCRATCH! said no responsible pill-taker ever. "
        "Get those pills down you, brave knight, before things escalate to 'just a flesh wound!'"
    ),
    (
        "We are the Knights Who Say... PILL! And we demand a shrubbery... "
        "AFTER you take your medication! PILL FIRST! SHRUBBERY SECOND!"
    ),
    (
        "NOBODY expects the Spanish Inquisition... but everybody expects "
        "YOU to take your pills! Our chief weapon is persistence! "
        "Take! Your! PILLS!"
    ),
    (
        "I'm not dead yet! And you won't be either, provided you take "
        "your medication! Now stop arguing and get those pills down you!"
    ),
    (
        "He's a very naughty boy! And he HASN'T TAKEN HIS PILLS! "
        "Don't be like Brian! Brian forgot! Don't be Brian!"
    ),
    (
        "What is the airspeed velocity of an unladen swallow? "
        "African or European? Doesn't MATTER — take your pills FIRST "
        "and we'll sort out the swallows afterward!"
    ),
    (
        "Brave Sir Robin ran away... but even Brave Sir Robin took his pills! "
        "Allegedly! The minstrel may have glossed over that part. PILL TIME!"
    ),
    (
        "I am Arthur, King of the Britons! And I hereby decree by royal "
        "proclamation that ALL pills shall be consumed at this very moment! "
        "The coconuts can wait!"
    ),
    (
        "RUN AWAY! Run away from Parkinson's symptoms! The only weapon "
        "against the terrible beast is... your PILLS! Fetch the pills!"
    ),
    (
        "SPAM! Spam spam spam spam! Spam pills spam! Wonderful pills! "
        "Except it is not spam — it is VERY IMPORTANT MEDICATION TIME!"
    ),
    (
        "Always look on the bright side of life! *whistles cheerfully* "
        "Which is much easier to do after you have taken your PILLS! "
        "So take them! Now! Please!"
    ),
    (
        "Tim the Enchanter has foreseen it! The pills must be taken! "
        "Ignore his warning and face... well, the consequences of "
        "not taking your medication, which I assure you are quite nasty!"
    ),
    (
        "Your mother was a hamster and your father smelt of elderberries! "
        "But more critically — IT IS PILL TIME! We shall taunt you "
        "a second time if you do not comply!"
    ),
    (
        "A moose once bit my sister... but that is not the point. "
        "The point is IT IS PILL O'CLOCK! The moose agrees! "
        "TAKE YOUR MEDICATION!"
    ),
    (
        "And now for something completely different... it is time for your PILLS! "
        "Which, come to think of it, is not that different from last time. "
        "Still! TAKE THEM!"
    ),
    (
        "The Black Knight NEVER surrenders! And neither shall YOU "
        "surrender to Parkinson's! Your sword is your medication! "
        "WIELD IT! Take! Those! PILLS!"
    ),
    # ── Additional phrases ──────────────────────────────────────────────────
    (
        "Bring out your pills! Bring out your pills! "
        "We're not dead yet — and with YOUR medication on schedule, "
        "we intend to keep it that way! PILLS! FORWARD!"
    ),
    (
        "Strange women lying in ponds may not distribute pills, "
        "but I AM distributing this reminder! "
        "The Lady of the Lake commands you: TAKE THEM!"
    ),
    (
        "On second thought, let's NOT forget the pills. "
        "'Tis a silly thing to do! Get them down you, "
        "and we shall say no more about the shrubbery incident."
    ),
    (
        "Dennis! Come see the medication not being taken! "
        "Help! Help! I'm being ignored by my own pill bottle! "
        "This is what happens when you skip doses, you see!"
    ),
    (
        "We have found a pill! May we take it? "
        "How do you know it's a pill? It LOOKS like one! "
        "And besides, it's MEDICATION TIME, so swallow it already!"
    ),
    (
        "Message for you, sir! MESSAGE FOR YOU, SIR! "
        "From the Castle of Your Doctor, via the trebuchet of good health: "
        "TAKE YOUR PILLS IMMEDIATELY! The castle demands it!"
    ),
    (
        "Sir Galahad the Pure must remain pure of MISSED DOSES! "
        "In the midst of his quest for the Holy Grail, even he "
        "paused to take his medication. Follow his noble example!"
    ),
    (
        "Listen, strange doctors in clinics distributing pills "
        "IS a basis for a health plan! "
        "Supreme executive power derives from a mandate — "
        "from YOUR PRESCRIPTION. Take it!"
    ),
    (
        "Now witness the firepower of this fully armed and operational "
        "pill reminder! Wait, wrong franchise. But the point stands: "
        "Your PILLS await, brave knight! The Holy Grail can wait!"
    ),
    (
        "Patsy! Are you SURE we can't stop for pills? "
        "King Arthur paused his coconut clapping to inform you: "
        "PILL O'CLOCK HAS ARRIVED. The kingdom depends upon it!"
    ),
    (
        "What have the Romans ever done for us? "
        "Well, modern medicine, sanitation, roads, aqueducts... "
        "and your PILLS. Which you should be taking RIGHT NOW!"
    ),
    (
        "I wish to complain about this pill reminder! "
        "'E's not complaining, 'e's resting! No — 'e's VERY MUCH AWAKE "
        "and needs to take his medication THIS INSTANT!"
    ),
    (
        "The Larch. The Larch. How to take your pills. "
        "Step one: open the bottle. Step two: take the pills. "
        "Step three: feel magnificent. TAKE THEM NOW!"
    ),
    (
        "We're the People's Front of Medication Reminders! "
        "Splitters! WHAT have we done for the patient? "
        "We REMIND them, every single time! It is our sacred duty!"
    ),
    (
        "I'm not sure that's entirely wise, sir — said nobody ever "
        "about taking medication on schedule! "
        "Even Baldrick's cunning plan involves taking pills. TAKE YOURS!"
    ),
    (
        "Ooh, I feel happy! I feel happy! "
        "That is because the previous patient took their pills on time. "
        "Be like that patient! Take yours! HAPPINESS AWAITS!"
    ),
    (
        "This is an EX-excuse! Your excuse for not taking your pills "
        "has CEASED TO BE! It has expired! "
        "TAKE! YOUR! MEDICATION! This is no time for bereft parrots!"
    ),
    (
        "Camelot! It's only a model — but your HEALTH is real! "
        "And real health requires real pills taken at real times! "
        "Which is RIGHT NOW! Onward, brave pill-taker!"
    ),
    (
        "We interrupt this quest for the Holy Grail "
        "to bring you a CRITICAL ANNOUNCEMENT: "
        "The God of Abraham commands thee — through your prescription — "
        "to TAKE THY PILLS! He's not angry, just very disappointed."
    ),
    (
        "I didn't vote for this pill reminder! "
        "You don't VOTE for pill reminders! "
        "But your doctor prescribed this medication, "
        "and the supreme executive of your health demands compliance!"
    ),
    (
        "Strange, isn't it, how every day at this hour "
        "a magical voice appears to tell you to take your medication? "
        "Some would call it enchanted. I call it PILL O'CLOCK. "
        "Take them IMMEDIATELY!"
    ),
    (
        "Fetchez la pilule! FETCHEZ LA PILULE! "
        "Go and fetch the sacred medication from its vessel! "
        "The French taunting can wait — your health cannot! "
        "Swallow them with great dignity and haste!"
    ),
]

ACKNOWLEDGMENT_PHRASES = [
    (
        "Splendid! The brave knight has consumed the sacred medication! "
        "King Arthur himself would be proud! Now hear ye the news from the realm..."
    ),
    (
        "Excellent! The Black Knight's symptoms may nip at your heels, "
        "but YOUR PILLS ARE TAKEN! Victory! Onward to the news..."
    ),
    (
        "Right, that's settled then! No more 'tis but a scratch' for you today. "
        "Well done! Now let us consult the oracles of news and weather..."
    ),
    (
        "BRILLIANT! A shrubbery! No wait — better than a shrubbery: "
        "you took your pills! Now for today's briefing from the kingdom..."
    ),
    (
        "And there was much rejoicing! The pills have been taken! "
        "Now let us see what chaos the outside world has managed today..."
    ),
    (
        "We are no longer the knights who say NIH — we are the knights "
        "who say WELL DONE! Pills consumed! Now for the news..."
    ),
]

# ─── AI phrase generation ─────────────────────────────────────────────────────
_GENERATED_PHRASES_FILE = os.path.join(os.path.dirname(__file__), "generated_phrases.json")


def _load_generated_phrases() -> list:
    try:
        if os.path.exists(_GENERATED_PHRASES_FILE):
            with open(_GENERATED_PHRASES_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
    except Exception:
        pass
    return []


def _save_generated_phrases(phrases: list) -> None:
    try:
        with open(_GENERATED_PHRASES_FILE, "w", encoding="utf-8") as f:
            json.dump(phrases, f, indent=2, ensure_ascii=False)
    except Exception as exc:
        log.warning("Could not save generated phrases: %s", exc)


def generate_ai_phrase() -> str | None:
    """Ask Claude Haiku to mint a fresh Monty Python pill reminder and cache it."""
    if not _ANTHROPIC_OK:
        return None
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return None
    try:
        client = _anthropic_sdk.Anthropic(api_key=api_key)
        response = client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=200,
            messages=[{
                "role": "user",
                "content": (
                    "Write ONE short, funny Monty Python-style pill reminder (2-4 sentences). "
                    "Reference a specific Monty Python character, quote, or scene in a fresh, creative way. "
                    "The recipient has Parkinson's disease and must take medication on time. "
                    "Be encouraging, silly, and affectionate — never mean. "
                    "Reply with only the reminder text. No quotes, no labels, no explanation."
                ),
            }],
        )
        phrase = response.content[0].text.strip()
        if phrase:
            phrases = _load_generated_phrases()
            phrases.append(phrase)
            _save_generated_phrases(phrases)
            log.info("Generated new AI phrase (%d total cached).", len(phrases))
            return phrase
    except Exception as exc:
        log.warning("AI phrase generation failed: %s", exc)
    return None


def _pick_reminder_phrase() -> str:
    """Pick from the combined static + AI-generated phrase pool.

    Also kicks off background AI generation 1-in-5 calls so the pool grows
    over time without blocking the reminder.
    """
    generated = _load_generated_phrases()
    pool = REMINDER_PHRASES + generated
    phrase = random.choice(pool)
    if _ANTHROPIC_OK and os.environ.get("ANTHROPIC_API_KEY") and random.random() < 0.20:
        threading.Thread(target=generate_ai_phrase, daemon=True).start()
    return phrase


# ─── Global state ─────────────────────────────────────────────────────────────
_reminder_active = False
_reminder_lock   = threading.Lock()
_recognizer      = None

# ─── Text-to-speech ───────────────────────────────────────────────────────────
def _configure_voice(engine):
    voices = engine.getProperty("voices")
    # Prefer a male English voice for gravitas
    preferred = ["david", "mark", "george", "english"]
    for pref in preferred:
        for v in voices:
            if pref in v.name.lower():
                engine.setProperty("voice", v.id)
                break
        else:
            continue
        break
    engine.setProperty("rate", 155)    # slightly slower = clearer
    engine.setProperty("volume", 1.0)


def _init_tts():
    """Startup sanity check — confirms pyttsx3/SAPI5 voices are available."""
    engine = pyttsx3.init()
    _configure_voice(engine)
    del engine
    log.info("TTS initialised.")


def speak(text: str):
    """Create a fresh engine bound to the calling thread.

    pyttsx3's SAPI5 driver wraps a COM voice object tied to the thread that
    created it — sharing one engine across the main thread and worker
    threads makes runAndWait() return immediately with no audio. Building a
    new engine per call keeps it on the calling thread and actually speaks.
    """
    log.info("TTS: %s", text[:100])
    try:
        engine = pyttsx3.init()
        _configure_voice(engine)
        engine.say(text)
        engine.runAndWait()
        del engine
    except Exception as exc:
        log.error("TTS error: %s", exc)


# ─── Location & weather ───────────────────────────────────────────────────────
def _get_location() -> str | None:
    try:
        data = requests.get("https://ipinfo.io/json", timeout=5).json()
        city   = data.get("city", "")
        region = data.get("region", "")
        return f"{city}, {region}" if city else None
    except Exception as exc:
        log.warning("Location lookup failed: %s", exc)
        return None


def get_weather_text() -> str:
    location = _get_location()
    try:
        url = (
            f"https://wttr.in/{location.replace(' ', '+')}?format=j1"
            if location
            else "https://wttr.in/?format=j1"
        )
        data    = requests.get(url, timeout=10).json()
        cur     = data["current_condition"][0]
        desc    = cur["weatherDesc"][0]["value"]
        temp_f  = cur["temp_F"]
        feel_f  = cur["FeelsLikeF"]
        humid   = cur["humidity"]
        area    = (
            data.get("nearest_area", [{}])[0]
                .get("areaName", [{}])[0]
                .get("value", location or "your area")
        )
        return (
            f"Weather in {area}: {desc}. "
            f"Temperature {temp_f} degrees Fahrenheit, feels like {feel_f}. "
            f"Humidity {humid} percent."
        )
    except Exception as exc:
        log.warning("Weather lookup failed: %s", exc)
        return (
            "The weather spirits are being most uncooperative today, "
            "much like those dreadful French knights."
        )


def get_fox_headlines() -> list[str]:
    for feed_url in (FOX_NEWS_RSS, FOX_NEWS_RSS_ALT):
        try:
            feed = feedparser.parse(feed_url)
            titles = [e.title for e in feed.entries[:NEWS_COUNT] if hasattr(e, "title")]
            if titles:
                return titles
        except Exception as exc:
            log.warning("RSS fetch failed (%s): %s", feed_url, exc)
    return ["The Fox News owls have apparently flown away with all the headlines. Most peculiar."]


# ─── Acknowledgment + post-ack delivery ───────────────────────────────────────
def _acknowledge():
    global _reminder_active
    with _reminder_lock:
        _reminder_active = False
    log.info("Reminder acknowledged.")
    threading.Thread(target=_deliver_news_and_weather, daemon=True).start()


def _deliver_news_and_weather():
    speak(random.choice(ACKNOWLEDGMENT_PHRASES))
    time.sleep(0.4)

    weather = get_weather_text()
    speak(f"First, the weather! {weather}")
    time.sleep(0.3)

    headlines = get_fox_headlines()
    speak("And now, the top headlines from Fox News!")
    for i, headline in enumerate(headlines, 1):
        speak(f"Headline {i}: {headline}")
        time.sleep(0.2)

    speak(
        "And that concludes today's briefing, brave knight. "
        "Always look on the bright side of life! "
        "We shall bother you again at the next appointed hour. Farewell!"
    )


# ─── Voice recognition ────────────────────────────────────────────────────────
def _record_with_sounddevice(duration: int, samplerate: int = 16000) -> sr.AudioData:
    """Record audio via sounddevice and return an sr.AudioData object."""
    frames = sd.rec(
        int(duration * samplerate),
        samplerate=samplerate,
        channels=1,
        dtype="int16",
        blocking=True,
    )
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(samplerate)
        wf.writeframes(frames.tobytes())
    buf.seek(44)   # skip WAV header
    return sr.AudioData(buf.read(), samplerate, 2)


def _listen_for_yes(timeout: int = LISTEN_SECONDS) -> bool:
    global _recognizer
    if not _VOICE_ENABLED:
        return False
    if _recognizer is None:
        _recognizer = sr.Recognizer()
    YES_WORDS = {"yes", "yeah", "yep", "yup", "done", "taken", "okay", "ok",
                 "confirmed", "aye", "affirmative", "right", "got it", "check"}
    try:
        if _PYAUDIO_OK:
            with sr.Microphone() as source:
                _recognizer.adjust_for_ambient_noise(source, duration=0.3)
                audio = _recognizer.listen(source, timeout=timeout, phrase_time_limit=4)
        else:
            # sounddevice path — record for `timeout` seconds
            audio = _record_with_sounddevice(min(timeout, 4))

        text = _recognizer.recognize_google(audio).lower()
        log.info("Heard: '%s'", text)
        return any(w in text for w in YES_WORDS)
    except sr.WaitTimeoutError:
        return False
    except sr.UnknownValueError:
        return False
    except Exception as exc:
        log.debug("Voice recognition error: %s", exc)
        return False


# ─── Reminder cycle ───────────────────────────────────────────────────────────
def _reminder_cycle():
    global _reminder_active

    with _reminder_lock:
        if _reminder_active:
            return          # already running
        _reminder_active = True

    log.info("Pill reminder triggered at %s", datetime.now().strftime("%H:%M"))

    attempt = 0
    while True:
        with _reminder_lock:
            if not _reminder_active:
                break

        phrase = _pick_reminder_phrase()
        speak(phrase)
        time.sleep(0.3)
        speak("Press any key, or say YES, to confirm you have taken your pills!")

        # Wait up to REMINDER_INTERVAL seconds for acknowledgment
        acknowledged  = False
        deadline      = time.time() + REMINDER_INTERVAL
        key_event     = threading.Event()

        def _on_key(_e):
            key_event.set()

        keyboard.on_press(_on_key)

        try:
            while time.time() < deadline:
                if key_event.is_set():
                    log.info("Acknowledged via keyboard.")
                    acknowledged = True
                    break
                if _listen_for_yes(timeout=min(LISTEN_SECONDS, int(deadline - time.time()) + 1)):
                    log.info("Acknowledged via voice.")
                    acknowledged = True
                    break
                # Check if an agent already cleared the flag
                with _reminder_lock:
                    if not _reminder_active:
                        acknowledged = True
                        break
        finally:
            keyboard.unhook_all()

        if acknowledged:
            _acknowledge()
            break

        attempt += 1
        log.info("No acknowledgment — repeating (attempt %d).", attempt)


# ─── Flask API for agent calls ────────────────────────────────────────────────
_flask_app = Flask(__name__)


@_flask_app.route("/acknowledge", methods=["POST"])
def api_acknowledge():
    """An external agent POSTs here to acknowledge the reminder."""
    if _reminder_active:
        _acknowledge()
        return jsonify({"status": "acknowledged"})
    return jsonify({"status": "no_active_reminder"})


@_flask_app.route("/status", methods=["GET"])
def api_status():
    return jsonify({
        "reminder_active": _reminder_active,
        "pill_times":      PILL_TIMES,
        "current_time":    datetime.now().strftime("%H:%M"),
    })


@_flask_app.route("/trigger", methods=["POST"])
def api_trigger():
    """Manually fire a reminder (for testing or agent-initiated check-ins)."""
    threading.Thread(target=_reminder_cycle, daemon=True).start()
    return jsonify({"status": "triggered"})


@_flask_app.route("/next", methods=["GET"])
def api_next():
    """Return time until next scheduled reminder."""
    now_min = datetime.now().hour * 60 + datetime.now().minute
    upcoming = []
    for t in PILL_TIMES:
        h, m = map(int, t.split(":"))
        total = h * 60 + m
        diff  = total - now_min
        if diff < 0:
            diff += 1440     # wrap to next day
        upcoming.append({"time": t, "minutes_until": diff})
    upcoming.sort(key=lambda x: x["minutes_until"])
    return jsonify({"next": upcoming[0] if upcoming else None, "all": upcoming})


def _run_flask():
    import logging as _lg
    _lg.getLogger("werkzeug").setLevel(_lg.ERROR)
    _flask_app.run(host="0.0.0.0", port=AGENT_PORT, debug=False, use_reloader=False)


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    _init_tts()

    # Schedule reminders
    for t in PILL_TIMES:
        schedule.every().day.at(t).do(
            lambda: threading.Thread(target=_reminder_cycle, daemon=True).start()
        )
        log.info("Scheduled pill reminder at %s", t)

    # Start agent API
    flask_thread = threading.Thread(target=_run_flask, daemon=True)
    flask_thread.start()
    log.info("Agent API listening on http://localhost:%d", AGENT_PORT)

    # Startup announcement
    voice_status = (
        "Voice recognition is active — simply say YES to confirm your pills!"
        if _VOICE_ENABLED
        else "Voice recognition is unavailable — press any key to confirm your pills."
    )
    speak(
        "Good news, brave knight! Your pill reminder system is now fully operational! "
        "You shall be reminded at seven in the morning, one in the afternoon, "
        "five in the evening, and nine at night. "
        f"{voice_status} "
        "The Black Knight of Parkinson's shall not pass! "
        "King Arthur himself endorses this message. "
        "I am... not dead yet!"
    )

    log.info("Pill reminder running. Press Ctrl+C to stop.")
    try:
        while True:
            schedule.run_pending()
            time.sleep(5)
    except KeyboardInterrupt:
        speak("Farewell, brave knight! Run away! Run away!")
        log.info("Pill reminder stopped.")
        sys.exit(0)


if __name__ == "__main__":
    main()
