#!/bin/zsh
# External health check for Pill Reminder, run by launchd every 5 minutes.
# Catches the "process alive but not working" case the in-process watchdog can't
# see (e.g. the whole process wedged). Three failed probes 10 s apart -> force restart.

LABEL="com.thibbledorf.pillreminder"
CONFIG="$HOME/Library/Application Support/PillReminder/config.json"
PORT=$(/usr/bin/plutil -extract api_port raw -o - "$CONFIG" 2>/dev/null)
[[ "$PORT" == <-> ]] || PORT=5055
TARGET="gui/$(id -u)/$LABEL"
stamp() { date "+%Y-%m-%d %H:%M:%S"; }

# Not loaded at all (e.g. uninstalled or manually booted out): do nothing.
/bin/launchctl print "$TARGET" >/dev/null 2>&1 || exit 0

for attempt in 1 2 3; do
    body=$(/usr/bin/curl -sS -m 8 "http://127.0.0.1:$PORT/health" 2>&1)
    if [[ $? -eq 0 && "$body" == *'"ok" : true'* ]]; then
        exit 0
    fi
    sleep 10
done

echo "$(stamp) health check failed 3x — restarting $LABEL. Last response: ${body:0:300}"
/bin/launchctl kickstart -k "$TARGET"
