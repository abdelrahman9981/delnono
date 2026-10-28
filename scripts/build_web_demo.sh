#!/bin/bash
# Builds the D-43 web demo: the guardian app (build/web_app) and the clinic dashboard
# (build/web_dashboard), as hosted on Firebase Hosting (firebase.json "hosting" targets).
#
#   scripts/build_web_demo.sh prod       # for dr-elnono-clinic (Web app drelnono-web)
#   scripts/build_web_demo.sh emulator   # the same apps against the local emulators (smoke test)
#
# Builds only; deploying is a separate, approved step (docs/demo-runbook.md).
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-}"

case "$MODE" in
  prod)
    # The Web app's config is in lib/core/firebase/firebase_options_prod.dart (public identifiers).
    DEFINES=(--dart-define=FIREBASE_ENV=prod)
    ;;
  emulator)
    DEFINES=(--dart-define=USE_EMULATOR=true)
    ;;
  *)
    echo "usage: $0 prod|emulator" >&2
    exit 2
    ;;
esac

build() { # target, output dir, page title
  flutter build web --release -t "$1" -o "$2" "${DEFINES[@]}"
  # One web/ folder serves both apps: give each its own title and install name.
  sed -i.bak -e "s|<title>.*</title>|<title>$3</title>|" \
    -e "s|content=\"DElnono Flutter application\"|content=\"$3\"|" \
    -e "s|apple-mobile-web-app-title\" content=\"[^\"]*\"|apple-mobile-web-app-title\" content=\"$3\"|" "$2/index.html"
  sed -i.bak -e "s|\"name\": \"delnono\"|\"name\": \"$3\"|" -e "s|\"short_name\": \"delnono\"|\"short_name\": \"$3\"|" "$2/manifest.json"
  rm -f "$2/index.html.bak" "$2/manifest.json.bak"
}

build lib/main.dart build/web_app "دكتور النونو"
build lib/dashboard/main.dart build/web_dashboard "دكتور النونو · العيادة"

if [ "$MODE" = prod ]; then
  # D-51: the development code swap (123456 for any number) exists only in emulator builds.
  for dir in build/web_app build/web_dashboard; do
    if grep -q "verificationCodes\|localhost:9099\|useAuthEmulator" "$dir/main.dart.js"; then
      echo "✗ $dir contains emulator-only code; refusing this prod build." >&2
      exit 1
    fi
  done
  echo "✓ prod web builds ready (no emulator code): build/web_app, build/web_dashboard"
else
  echo "✓ emulator web builds ready: build/web_app, build/web_dashboard"
fi
