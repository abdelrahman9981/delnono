#!/bin/bash
# The iOS release build for TestFlight: version 1.0.0 (build 1 unless BUILD_NUMBER is set), bundle id
# eg.drelnono.app, the real project dr-elnono-clinic (FIREBASE_ENV=prod). Builds and archives only;
# uploading is done by the owner from Xcode Organizer (docs/store/testflight.md).
#
#   scripts/build_ios_release.sh
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_NUMBER="${BUILD_NUMBER:-1}"

plutil -lint ios/Runner/Info.plist ios/Runner/PrivacyInfo.xcprivacy ios/Runner/Runner.entitlements

flutter build ipa --release --dart-define=FIREBASE_ENV=prod --build-name=1.0.0 --build-number="$BUILD_NUMBER"

ARCHIVE="build/ios/archive/Runner.xcarchive"
APP="$ARCHIVE/Products/Applications/Runner.app"
# D-51: the development code swap (123456 for any number) exists only in emulator builds. Its tell-tale
# strings must not be in the compiled Dart code of this build.
BIN="$APP/Frameworks/App.framework/App"
if strings "$BIN" | grep -q -e "verificationCodes" -e "localhost:9099" -e "AIzaDemoKeyForLocalEmulatorsOnly"; then
  echo "✗ the release build contains emulator-only code; refusing it." >&2
  exit 1
fi
echo "✓ no emulator code in $BIN"
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" -c "Print CFBundleShortVersionString" -c "Print CFBundleVersion" \
  -c "Print CFBundleDisplayName" "$APP/Info.plist"
echo "Archive: $ARCHIVE (open it in Xcode Organizer to upload)"
