# Voice Models & Configuration

This document describes voice synthesis options and configuration for Pill Reminder across platforms.

## Phase 1: Local TTS (Built-in)

Each platform uses its native text-to-speech engine. No API keys required, works offline.

### iOS & macOS: AVSpeechSynthesizer

**Available Voices:**
```swift
// English voices available on iOS/macOS:
AVSpeechSynthesisVoice(language: "en-US")  // Default US voice
AVSpeechSynthesisVoice(language: "en-GB")  // British English
AVSpeechSynthesisVoice(language: "en-AU")  // Australian English
AVSpeechSynthesisVoice(language: "en-IE")  // Irish English
AVSpeechSynthesisVoice(language: "en-ZA")  // South African English

// Other languages also supported
```

**Configuration:**
```swift
var utterance = AVSpeechUtterance(string: "Take your medication")

// Rate (0.0 = slowest, 1.0 = normal, 2.0 = fastest)
utterance.rate = 0.8

// Pitch (0.5 = lower, 1.0 = normal, 2.0 = higher)
utterance.pitchMultiplier = 1.0

// Volume (0.0 - 1.0)
utterance.volume = 0.8

// Pause between words
utterance.postUtteranceDelay = 0.5
```

**Advantages:**
- Free
- Works offline
- Reliable
- Multiple voice options
- Good enough for medication reminders

**Disadvantages:**
- Less natural than premium services
- Limited personality/emotion

### Windows: System.Speech

```csharp
using System.Speech.Synthesis;

var synthesizer = new SpeechSynthesizer();

// Rate (-10 to 10, 0 is normal)
synthesizer.Rate = -2;

// Volume (0 to 100)
synthesizer.Volume = 80;

synthesizer.Speak("Take your medication");
```

### Linux: pyttsx3 or espeak

**pyttsx3 (Python):**
```python
import pyttsx3

engine = pyttsx3.init()

# Rate (words per minute)
engine.setProperty('rate', 150)

# Volume (0.0 - 1.0)
engine.setProperty('volume', 0.8)

# Voice ID (platform-dependent)
engine.setProperty('voice', voice_id)

engine.say("Take your medication")
engine.runAndWait()
```

**espeak (Linux CLI):**
```bash
espeak "Take your medication" -s 150 -a 80
```

## Phase 2: Optional API Integration

### Eleven Labs (Recommended)

Premium natural-sounding voices. Perfect for Monty Python character voices.

**Setup:**
1. Create account at [elevenlabs.io](https://elevenlabs.io)
2. Generate API key from settings
3. User stores key in app (Keychain on iOS/macOS, secure storage on Windows)

**Configuration:**
```swift
// ios/PillReminder/Services/VoiceManager.swift

let apiKey = KeychainHelper.retrieve(key: "elevenlabs_api_key")
let voiceId = "21m00Tcm4TlvDq8ikWAM"  // "Rachel" voice (natural female)
let model = "eleven_monolingual_v1"

// Request parameters
let requestBody = [
    "text": "Take your medication with Parkinsons",
    "voice_settings": [
        "stability": 0.5,
        "similarity_boost": 0.8
    ]
] as [String : Any]

var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!)
request.httpMethod = "POST"
request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

// Fetch audio data
let (data, _) = try await URLSession.shared.data(for: request)
// Play audio with AVAudioPlayer
```

**Voice Options:**
```
21m00Tcm4TlvDq8ikWAM - Rachel (natural, professional)
EXAVITQu4vr4xnSDxMaL - Bella (warm, friendly)
XB0fDUnqU2EQe6yGcIOp - Antoni (male, deep)
MF3mGyEYCl7XYWbV7PpE - Elli (female, young)
TxGEqnHWrfWFTfGW9XjX - Josh (male, young)

// Custom cloned voices available for premium users
```

**Limitations:**
- 10,000 characters/month free tier
- Paid plans: €5-99/month
- Requires internet connection
- Fallback: if API unavailable, use local TTS

### Google Cloud Text-to-Speech

Alternative premium option.

**Setup:**
```bash
# Install Google Cloud SDK
pip install google-cloud-texttospeech

# Authenticate
gcloud auth application-default login
```

**Configuration:**
```python
from google.cloud import texttospeech

client = texttospeech.TextToSpeechClient()

synthesis_input = texttospeech.SynthesisInput(text="Take your medication")

voice = texttospeech.VoiceSelectionParams(
    language_code="en-US",
    name="en-US-Neural2-A"  # Neural voices (most natural)
)

audio_config = texttospeech.AudioConfig(
    audio_encoding=texttospeech.AudioEncoding.MP3,
    pitch=0.0,
    speaking_rate=1.0
)

response = client.synthesize_speech(
    input=synthesis_input,
    voice=voice,
    audio_config=audio_config
)

# response.audio_content contains MP3 bytes
```

**Neural Voices:**
- More natural than standard voices
- Support multiple languages
- Good for long audio

**Pricing:**
- First 1 million characters/month: free
- Additional characters: $15-16 per 1M characters

## Monty Python Voice Personas (Phase 2+)

For users who want character-specific voices:

```json
{
  "personas": [
    {
      "id": "general",
      "name": "General Reminder",
      "description": "Neutral reminder with Monty Python jokes",
      "voiceId": "21m00Tcm4TlvDq8ikWAM",  // Rachel (Eleven Labs)
      "rate": 0.9,
      "pitch": 1.0
    },
    {
      "id": "lumberjack",
      "name": "Lumberjack",
      "description": "Brash, masculine voice",
      "voiceId": "XB0fDUnqU2EQe6yGcIOp",  // Antoni (Eleven Labs)
      "rate": 0.85,
      "pitch": 0.8
    },
    {
      "id": "ministry",
      "name": "Ministry Official",
      "description": "Stuffy, bureaucratic tone",
      "voiceId": "EXAVITQu4vr4xnSDxMaL",  // Bella (Eleven Labs)
      "rate": 0.95,
      "pitch": 1.2
    },
    {
      "id": "narrator",
      "name": "Narrator",
      "description": "Dramatic, storytelling voice",
      "voiceId": "MF3mGyEYCl7XYWbV7PpE",  // Elli (Eleven Labs)
      "rate": 1.0,
      "pitch": 0.9
    }
  ]
}
```

## Voice Alert Text Templates

These are generated dynamically. Examples:

```
"Take your {malady_word} medication! {joke}. You have {malady}. 
{weather_optional} {news_optional}"

Examples with Parkinsons:
"Take your Parkinsons medication! 
He's not actually a moose, he's very deeply disturbed. 
You have Parkinsons. 
Today's weather is partly cloudy with a high of 72 degrees."

"Time for your Parkinsons medication! 
Nudge nudge, wink wink, say no more! 
You have Parkinsons."

"Don't forget your Parkinsons pills! 
It's a fair cop, but society is to blame. 
You have Parkinsons. 
Top news: Scientists discover new breakthrough in neurological research."
```

## Voice Rate Recommendations

| Rate | Use Case | Example |
|------|----------|---------|
| 0.5 | Slow, clear speech | Elderly users, hearing impaired |
| 0.7 | Normal, deliberate | Default setting |
| 1.0 | Standard speech | English natives, normal pace |
| 1.3 | Faster speech | Younger users, frequent reminders |
| 1.5+ | Very fast | Quick confirmation |

## Voice Testing UI

In app, users should be able to:

1. **Test Current Settings:**
   - Button: "Test Voice"
   - Speaks sample text with current rate/volume
   - No malady: `"Take your medication! [joke]"`
   - With malady: `"Take your medication! [joke]. You have [malady]."`

2. **Rate Slider:**
   - Range: 0.5 - 2.0
   - Updates preview in real-time
   - Shows numeric value

3. **Volume Slider:**
   - Range: 0.0 - 1.0
   - Updates preview in real-time
   - Shows percentage (0-100%)

4. **Voice Selection Dropdown:**
   - Shows available voices for platform
   - Displays voice language/accent
   - Clicking selects voice for test

## Configuration Storage

**iOS/macOS (UserDefaults):**
```swift
let defaults = UserDefaults.standard
defaults.set("21m00Tcm4TlvDq8ikWAM", forKey: "voiceId")
defaults.set(0.9, forKey: "voiceRate")
defaults.set(0.8, forKey: "volumeLevel")
```

**Windows (Registry or Settings file):**
```csharp
// Via registry
RegistryKey key = Registry.CurrentUser.CreateSubKey("Software\\PillReminder");
key.SetValue("VoiceId", "Rachel");
key.SetValue("VoiceRate", 0.9);
```

**Linux (Config file ~/.config/pillreminder/config.json):**
```json
{
  "voice": {
    "id": "default",
    "rate": 0.9,
    "volume": 0.8
  }
}
```

## API Keys & Security

**Storing API Keys:**

- **iOS/macOS:** Use Keychain
  ```swift
  import Security
  KeychainHelper.save(key: "elevenlabs_api_key", value: apiKey)
  ```

- **Windows:** Use Data Protection API (DPAPI)
  ```csharp
  var data = Encoding.UTF8.GetBytes(apiKey);
  var protectedData = ProtectedData.Protect(data, null, DataProtectionScope.CurrentUser);
  ```

- **Linux:** Use pass or Secret Service
  ```bash
  pass insert pillreminder/elevenlabs_key
  ```

**Never:**
- Commit API keys to git
- Store in plaintext
- Transmit unencrypted
- Share with other apps

## Testing

Test voice synthesis with:

```swift
// Test local TTS
VoiceManager.test(withMalady: "Parkinsons", addOns: ["news", "weather"])

// Test API-based TTS (Phase 2)
VoiceManager.testWithAPI(voiceId: "21m00Tcm4TlvDq8ikWAM")
```

## Fallback Strategy

If API unavailable or key missing:
1. Silently fall back to local TTS
2. Show toast: "Using built-in voice (API unavailable)"
3. Continue functioning normally
4. No failure or crash
