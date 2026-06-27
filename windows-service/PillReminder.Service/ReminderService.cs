namespace PillReminder;

public class ReminderService
{
    private readonly VoiceManager _voice;
    private readonly SemaphoreSlim _cycleLock = new(1, 1);
    private volatile bool _reminderActive;

    public bool ReminderActive => _reminderActive;

    public ReminderService(VoiceManager voice) => _voice = voice;

    // ── Scheduling loop ────────────────────────────────────────────────────────

    public async Task RunAsync(CancellationToken ct)
    {
        var lastCheck = DateTime.Now;
        var firedToday = new HashSet<string>();
        var lastDate   = DateTime.Today;

        while (!ct.IsCancellationRequested)
        {
            await Task.Delay(5_000, ct).ContinueWith(_ => { }); // swallow cancellation

            var now = DateTime.Now;

            // Reset fired-set at midnight
            if (DateTime.Today != lastDate)
            {
                firedToday.Clear();
                lastDate = DateTime.Today;
            }

            var cfg = Config.Load();
            var gapSeconds = (now - lastCheck).TotalSeconds;

            // Sleep-wake recovery: if > 120 s gap, check for missed reminders
            if (gapSeconds > 120)
            {
                Log.Info($"Gap of {gapSeconds:F0}s detected — checking for missed reminders");
                foreach (var t in cfg.PillTimes)
                {
                    if (!TryParseTime(t, out int h, out int m)) continue;
                    var scheduled = now.Date.AddHours(h).AddMinutes(m);
                    if (lastCheck < scheduled && scheduled <= now && !firedToday.Contains(t))
                    {
                        Log.Info($"Firing missed reminder for {t}");
                        firedToday.Add(t);
                        FireReminder(ct);
                        break;
                    }
                }
            }

            // Normal schedule: fire when the clock first ticks into a configured minute
            foreach (var t in cfg.PillTimes)
            {
                if (!TryParseTime(t, out int h, out int m)) continue;
                if (now.Hour == h && now.Minute == m && !firedToday.Contains(t))
                {
                    Log.Info($"Firing scheduled reminder at {t}");
                    firedToday.Add(t);
                    FireReminder(ct);
                    break;
                }
            }

            lastCheck = now;
        }
    }

    // ── Public API surface (for HttpApi) ───────────────────────────────────────

    public void TriggerNow(CancellationToken ct = default)
    {
        if (_reminderActive)
        {
            Log.Info("TriggerNow called but reminder already active — ignoring.");
            return;
        }
        FireReminder(ct);
    }

    public void Acknowledge()
    {
        _reminderActive = false;
        Log.Info("Reminder acknowledged via API.");
    }

    public object GetNextInfo()
    {
        var cfg = Config.Load();
        var nowMin = DateTime.Now.Hour * 60 + DateTime.Now.Minute;

        var all = cfg.PillTimes
            .Where(t => TryParseTime(t, out _, out _))
            .Select(t =>
            {
                TryParseTime(t, out int h, out int m);
                int total = h * 60 + m;
                int diff  = total - nowMin;
                if (diff < 0) diff += 1440;
                return new { time = t, minutes_until = diff };
            })
            .OrderBy(x => x.minutes_until)
            .ToList();

        return new { next = all.FirstOrDefault(), all };
    }

    // ── Reminder cycle ─────────────────────────────────────────────────────────

    private void FireReminder(CancellationToken ct) =>
        Task.Run(() => ReminderCycleAsync(ct));

    private async Task ReminderCycleAsync(CancellationToken ct)
    {
        if (!await _cycleLock.WaitAsync(0))
        {
            Log.Info("Reminder cycle already running — skipping.");
            return;
        }

        _reminderActive = true;
        Log.Info($"Pill reminder triggered at {DateTime.Now:HH:mm}");

        try
        {
            int attempt = 0;

            while (!ct.IsCancellationRequested && _reminderActive)
            {
                var attemptStart = DateTime.Now;
                var cfg    = Config.Load();
                var phrase = Phrases.PickReminder(cfg.Malady);

                Console.Beep(880, 300);
                await Task.Delay(300, ct);

                _voice.Speak(phrase);
                _voice.Speak("Say YES to confirm you have taken your pills!");

                bool acked = await _voice.ListenForYesAsync(8, ct);

                if (!acked && _reminderActive)
                {
                    _voice.Speak("I didn't hear you! Say YES if you have taken your pills!");
                    acked = await _voice.ListenForYesAsync(8, ct);
                }

                if (acked || !_reminderActive)
                {
                    _reminderActive = false;
                    Log.Info("Reminder acknowledged.");
                    _ = Task.Run(() => DeliverNewsAndWeatherAsync(ct));
                    break;
                }

                attempt++;
                Log.Info($"No acknowledgment — repeating (attempt {attempt})");

                // Wait out the remainder of the 60-second cycle
                var elapsed = (DateTime.Now - attemptStart).TotalSeconds;
                var wait    = Math.Max(2, 60 - elapsed);
                await Task.Delay(TimeSpan.FromSeconds(wait), ct).ContinueWith(_ => { });
            }
        }
        catch (Exception ex)
        {
            Log.Error($"Reminder cycle crashed: {ex.Message}");
        }
        finally
        {
            _reminderActive = false;
            _cycleLock.Release();
        }
    }

    private async Task DeliverNewsAndWeatherAsync(CancellationToken ct)
    {
        try
        {
            _voice.Speak(Phrases.PickAcknowledgment());
            await Task.Delay(400, ct);

            var weather = await NewsWeather.GetWeatherAsync();
            _voice.Speak($"First, the weather! {weather}");
            await Task.Delay(300, ct);

            var headlines = await NewsWeather.GetFoxHeadlinesAsync();
            _voice.Speak("And now, the top headlines from Fox News!");
            for (int i = 0; i < headlines.Count; i++)
            {
                _voice.Speak($"Headline {i + 1}: {headlines[i]}");
                await Task.Delay(200, ct);
            }

            _voice.Speak(
                "And that concludes today's briefing, brave knight. " +
                "Always look on the bright side of life! " +
                "We shall bother you again at the next appointed hour. Farewell!");
        }
        catch (Exception ex)
        {
            Log.Error($"News/weather delivery failed: {ex.Message}");
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private static bool TryParseTime(string s, out int hour, out int minute)
    {
        hour = minute = 0;
        var parts = s.Split(':');
        return parts.Length == 2
            && int.TryParse(parts[0], out hour)
            && int.TryParse(parts[1], out minute);
    }
}
