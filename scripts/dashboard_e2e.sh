#!/bin/bash
# Browser end-to-end test of the clinic dashboard against the Firebase emulators (005).
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
functions/node_modules/.bin/firebase emulators:exec --only auth,firestore,functions --import=./emulator-seed \
  "cd functions && npx tsx scripts/e2e-dashboard-setup.ts && cd .. && flutter drive \
    --driver=test_driver/integration_test.dart --target=integration_test/dashboard/dashboard_test.dart \
    -d web-server --browser-name=chrome --headless --dart-define=USE_EMULATOR=true"
