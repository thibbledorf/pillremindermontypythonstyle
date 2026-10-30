#!/bin/zsh
# Builds "Pill Reminder.app" and an installer package:
#   macos/dist/PillReminder-<version>.pkg
# Needs only the Xcode Command Line Tools.
set -euo pipefail

VERSION="1.0.0"
BUILD=$(date +%Y%m%d%H%M)
ID="com.thibbledorf.pillreminder"

HERE="${0:A:h}"
cd "$HERE"
DIST="$HERE/dist"
STAGE="$HERE/.stage"
APP="$STAGE/root/Applications/Pill Reminder.app"

echo "==> Compiling (release)"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/PillReminder"

echo "==> Assembling app bundle"
rm -rf "$STAGE"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$DIST"
cp "$BIN" "$APP/Contents/MacOS/PillReminder"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Support/Info.plist > "$APP/Contents/Info.plist"
cp Support/com.thibbledorf.pillreminder.plist \
   Support/com.thibbledorf.pillreminder.healthcheck.plist \
   Support/healthcheck.sh \
   Support/uninstall.sh \
   "$APP/Contents/Resources/"
chmod 755 "$APP/Contents/Resources/healthcheck.sh" "$APP/Contents/Resources/uninstall.sh"

echo "==> Ad-hoc code signing"
xattr -cr "$APP"
codesign --force --sign - --identifier "$ID" "$APP"
codesign --verify --verbose=1 "$APP"

echo "==> Building installer package"
chmod 755 Support/scripts/preinstall Support/scripts/postinstall
COMPONENTS="$STAGE/components.plist"
pkgbuild --analyze --root "$STAGE/root" "$COMPONENTS"
# Never "relocate" the install to some other copy of the app found on disk.
/usr/bin/plutil -replace 0.BundleIsRelocatable -bool NO "$COMPONENTS"
PKG="$DIST/PillReminder-$VERSION.pkg"
COPYFILE_DISABLE=1 pkgbuild --root "$STAGE/root" \
         --component-plist "$COMPONENTS" \
         --scripts Support/scripts \
         --identifier "$ID.pkg" \
         --version "$VERSION" \
         --install-location / \
         "$PKG"

echo
echo "Built: $PKG"
