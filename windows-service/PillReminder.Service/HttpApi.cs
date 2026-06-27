using System.Net;
using System.Text;
using System.Text.Json;

namespace PillReminder;

public class HttpApi
{
    private readonly ReminderService _reminder;
    private readonly HttpListener _listener = new();

    public HttpApi(ReminderService reminder)
    {
        _reminder = reminder;
        _listener.Prefixes.Add("http://127.0.0.1:5000/");
    }

    public async Task RunAsync(CancellationToken ct)
    {
        try { _listener.Start(); }
        catch (Exception ex)
        {
            Log.Warn($"HTTP API failed to start: {ex.Message}");
            return;
        }

        Log.Info("HTTP API listening on http://127.0.0.1:5000/");

        while (!ct.IsCancellationRequested)
        {
            try
            {
                var ctx = await _listener.GetContextAsync().WaitAsync(ct);
                _ = Task.Run(() => HandleAsync(ctx, ct));
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex) { Log.Warn($"HTTP accept error: {ex.Message}"); }
        }

        _listener.Stop();
    }

    private async Task HandleAsync(HttpListenerContext ctx, CancellationToken ct)
    {
        var req  = ctx.Request;
        var resp = ctx.Response;
        resp.ContentType = "application/json; charset=utf-8";

        object? result = null;
        int status = 200;

        try
        {
            var path   = req.Url?.AbsolutePath ?? "/";
            var method = req.HttpMethod;

            if (path == "/acknowledge" && method == "POST")
            {
                if (_reminder.ReminderActive)
                {
                    _reminder.Acknowledge();
                    result = new { status = "acknowledged" };
                }
                else
                {
                    result = new { status = "no_active_reminder" };
                }
            }
            else if (path == "/status" && method == "GET")
            {
                var cfg = Config.Load();
                result = new
                {
                    reminder_active = _reminder.ReminderActive,
                    pill_times      = cfg.PillTimes,
                    current_time    = DateTime.Now.ToString("HH:mm"),
                };
            }
            else if (path == "/trigger" && method == "POST")
            {
                _reminder.TriggerNow(ct);
                result = new { status = "triggered" };
            }
            else if (path == "/next" && method == "GET")
            {
                result = _reminder.GetNextInfo();
            }
            else
            {
                status = 404;
                result = new { error = "not found" };
            }
        }
        catch (Exception ex)
        {
            status = 500;
            result = new { error = ex.Message };
            Log.Error($"HTTP handler error: {ex.Message}");
        }

        resp.StatusCode = status;
        var bytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(result));
        resp.ContentLength64 = bytes.Length;
        await resp.OutputStream.WriteAsync(bytes, ct);
        resp.Close();
    }
}
