using System.Speech.Recognition;
using System.Speech.Synthesis;

namespace PillReminder;

public class VoiceManager
{
    // Preference lists — searched in order, first match wins
    private static readonly Dictionary<(string gender, string accent), string[]> _prefs = new()
    {
        { ("male",   "british"),  ["george", "daniel", "david", "mark"] },
        { ("male",   "american"), ["david", "mark", "george", "daniel"] },
        { ("female", "british"),  ["hazel", "susan", "zira", "eva"] },
        { ("female", "american"), ["zira", "eva", "cortana", "hazel", "susan"] },
    };

    private static void SelectVoice(SpeechSynthesizer synth, string gender, string accent)
    {
        var key = (gender.ToLowerInvariant(), accent.ToLowerInvariant());
        var prefs = _prefs.TryGetValue(key, out var p) ? p : ["david", "george", "zira", "hazel"];
        var installed = synth.GetInstalledVoices().Where(v => v.Enabled).ToList();

        Log.Info($"Installed voices: {string.Join(", ", installed.Select(v => v.VoiceInfo.Name))}");

        foreach (var pref in prefs)
        {
            var match = installed.FirstOrDefault(v =>
                v.VoiceInfo.Name.Contains(pref, StringComparison.OrdinalIgnoreCase));
            if (match != null)
            {
                synth.SelectVoice(match.VoiceInfo.Name);
                Log.Info($"Voice selected: {match.VoiceInfo.Name}");
                return;
            }
        }

        // Fallback to first available
        if (installed.Count > 0)
        {
            synth.SelectVoice(installed[0].VoiceInfo.Name);
            Log.Warn($"No preferred voice found — using: {installed[0].VoiceInfo.Name}");
        }
    }

    public void Speak(string text)
    {
        Log.Info($"TTS: {text[..Math.Min(80, text.Length)]}...");
        try
        {
            var cfg = Config.Load();
            using var synth = new SpeechSynthesizer();
            SelectVoice(synth, cfg.VoiceGender, cfg.VoiceAccent);
            synth.Rate = 1;    // -10 to 10; 0 = normal, 1 = slightly faster
            synth.Volume = 100;
            synth.Speak(text);
        }
        catch (Exception ex)
        {
            Log.Error($"TTS error: {ex.Message}");
        }
    }

    // YES-words the grammar will accept
    private static readonly string[] _yesWords =
        ["yes", "yeah", "yep", "done", "taken", "okay", "ok", "confirmed", "aye", "affirmative", "right"];

    public async Task<bool> ListenForYesAsync(int timeoutSeconds, CancellationToken ct)
    {
        var tcs = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);

        try
        {
            using var recognizer = new SpeechRecognitionEngine();
            var grammar = new Grammar(new GrammarBuilder(new Choices(_yesWords)));
            recognizer.LoadGrammar(grammar);
            recognizer.SetInputToDefaultAudioDevice();

            recognizer.SpeechRecognized += (_, e) =>
            {
                if (e.Result.Confidence > 0.4f)
                {
                    Log.Info($"Heard: '{e.Result.Text}' (confidence {e.Result.Confidence:P0})");
                    tcs.TrySetResult(true);
                }
            };

            recognizer.RecognizeAsync(RecognizeMode.Multiple);

            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds));
            using var linked  = CancellationTokenSource.CreateLinkedTokenSource(ct, timeout.Token);

            try
            {
                await tcs.Task.WaitAsync(linked.Token);
                return true;
            }
            catch (OperationCanceledException)
            {
                return false;
            }
            finally
            {
                try { recognizer.RecognizeAsyncStop(); } catch { }
            }
        }
        catch (Exception ex)
        {
            Log.Warn($"Voice recognition unavailable: {ex.Message}");
            // If no mic, wait the timeout so the caller's cycle timing stays consistent
            await Task.Delay(TimeSpan.FromSeconds(timeoutSeconds), ct).ContinueWith(_ => { });
            return false;
        }
    }
}
