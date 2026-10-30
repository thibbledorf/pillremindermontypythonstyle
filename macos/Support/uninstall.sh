#!/bin/zsh
# Removes Pill Reminder. Settings, phrase cache and logs are kept unless --purge is given.
# Run with: sudo zsh "/Applications/Pill Reminder.app/Contents/Resources/uninstall.sh"
set -u
USER_NAME=$(/usr/bin/stat -f%Su /dev/console)
USER_ID=$(/usr/bin/id -u "$USER_NAME")
USER_HOME=$(/usr/bin/dscl . -read "/Users/$USER_NAME" NFSHomeDirectory | /usr/bin/awk '{print $2}')

for label in com.thibbledorf.pillreminder.healthcheck com.thibbledorf.pillreminder; do
    /bin/launchctl bootout "gui/$USER_ID/$label" 2>/dev/null
    /bin/rm -f "$USER_HOME/Library/LaunchAgents/$label.plist"
done
/usr/bin/pkill -x PillReminder 2>/dev/null

/bin/rm -rf "/Applications/Pill Reminder.app"
/usr/sbin/pkgutil --forget com.thibbledorf.pillreminder.pkg >/dev/null 2>&1

if [[ "${1:-}" == "--purge" ]]; then
    /bin/rm -rf "$USER_HOME/Library/Application Support/PillReminder" "$USER_HOME/Library/Logs/PillReminder"
    /usr/bin/sudo -u "$USER_NAME" /usr/bin/security delete-generic-password -s PillReminderMontyPython >/dev/null 2>&1
    echo "Pill Reminder removed, including settings, phrase cache, logs and API key."
else
    echo "Pill Reminder removed. Settings and phrase cache kept in ~/Library/Application Support/PillReminder."
fi
