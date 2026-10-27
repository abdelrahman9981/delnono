#!/bin/bash
# Browser end-to-end tests against the Firebase emulators: the clinic dashboard (005) and the guardian
# app as the D-43 web demo, at phone (390×844) and desktop (1440×900) sizes. Run by
# scripts/merge_feature.sh --e2e.
# Needs Chrome and a matching chromedriver on PATH or in $CHROMEDRIVER:
#   npx @puppeteer/browsers install chromedriver@<your Chrome version>
set -euo pipefail
cd "$(dirname "$0")/.."
DRIVER="${CHROMEDRIVER:-$(command -v chromedriver || true)}"
[ -x "$DRIVER" ] || { echo "chromedriver not found (set CHROMEDRIVER)"; exit 2; }
"$DRIVER" --port=4444 >/dev/null 2>&1 &
DRIVER_PID=$!
trap 'kill $DRIVER_PID 2>/dev/null || true' EXIT
(cd functions && npm run build >/dev/null)
EMULATORS=(functions/node_modules/.bin/firebase emulators:exec --only auth,firestore,functions --import=./emulator-seed)
DRIVE="flutter drive --driver=test_driver/integration_test.dart -d web-server --browser-name=chrome --headless --dart-define=USE_EMULATOR=true"

echo "== dashboard (desktop)"
"${EMULATORS[@]}" "cd functions && npx tsx scripts/e2e-dashboard-setup.ts && cd .. && \
  $DRIVE --target=integration_test/dashboard/dashboard_test.dart"

# Each size on a fresh seed: the phone run's booking would block the desktop run's day.
for size in 390,844 1440,900; do
  echo "== guardian web demo ($size)"
  "${EMULATORS[@]}" "$DRIVE --browser-dimension=$size --target=integration_test/web/guardian_web_test.dart"
done
