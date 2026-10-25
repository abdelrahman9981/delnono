#!/bin/bash
# Merges a feature branch into main and pushes main only if every check passes on the merged code:
# flutter analyze, all Flutter tests, all Functions tests and the rules tests. Success is decided by
# each command's exit code, never by reading its output. On any failure the merge is undone locally
# and nothing is pushed.
#
#   scripts/merge_feature.sh <branch> "<merge message>" [--e2e]
#
# --e2e also runs the dashboard browser test (scripts/dashboard_e2e.sh; needs chromedriver).
set -uo pipefail
cd "$(dirname "$0")/.."

BRANCH="${1:?branch}"
MESSAGE="${2:?merge message}"
E2E="${3:-}"
LOGS="$(mktemp -d)"

# Builds touch generated platform files and file stamps; drop those, then go back to main as it was.
undo() {
  git checkout -- linux windows macos/Flutter 2>/dev/null
  git update-index -q --refresh
  if ! git reset --keep "$BEFORE"; then
    echo "✗ Could not undo the merge automatically. main is NOT pushed. Run: git reset --keep $BEFORE"
    exit 3
  fi
}

fail() {
  echo "✗ $1 failed — see $LOGS/$2. Undoing the merge; main is NOT pushed."
  undo
  exit 1
}

[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Working tree has changes; commit or stash first."; exit 2; }
git checkout main && git pull --ff-only || exit 2
BEFORE="$(git rev-parse HEAD)"
git merge --no-ff "$BRANCH" -m "$MESSAGE" || { git merge --abort 2>/dev/null; echo "Merge conflict; nothing pushed."; exit 2; }

echo "· flutter analyze";   flutter analyze >"$LOGS/analyze.log" 2>&1           || fail "flutter analyze" analyze.log
echo "· flutter test";      flutter test >"$LOGS/flutter.log" 2>&1              || fail "flutter test" flutter.log
echo "· functions tests";   (cd functions && npm test) >"$LOGS/functions.log" 2>&1 || fail "functions tests" functions.log
echo "· rules tests";       (cd functions && npm run test:rules) >"$LOGS/rules.log" 2>&1 || fail "rules tests" rules.log
if [ "$E2E" = "--e2e" ]; then
  echo "· dashboard e2e";   scripts/dashboard_e2e.sh >"$LOGS/e2e.log" 2>&1     || fail "dashboard e2e" e2e.log
fi

echo "✓ all checks passed; pushing main"
git push origin main
echo "logs: $LOGS"
