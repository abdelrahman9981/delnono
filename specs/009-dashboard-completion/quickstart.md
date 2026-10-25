# Quickstart: Dashboard Completion

Prerequisites: emulators with `emulator-seed/` (auth, firestore, functions); dashboard `flutter run -d chrome -t lib/dashboard/main.dart --dart-define=USE_EMULATOR=true`; seeded staff, password `Delnono-2026`.

1. **Desk registration** — sign in as `sec1@demo.delnono`; Children → "+ تسجيل أسرة"; number 01000000077, two children; both files open; record a weight.
2. **Linking in the app** — run the guardian app on the simulator, sign in with +201000000077 (test number), finish registration, give one child's birth date: both children appear with the weight.
3. **Duplicate** — register one of them again with other spelling: the warning names the existing child and opens it; nothing new.
4. **Merge** — create a second file for a child on a number (other spelling), add a measurement to each; as `doctor@demo.delnono`, open one → "دمج ملف مكرر" → pick the other → confirm; the kept file has both measurements; search no longer finds the other.
5. **Staff link** — lock linking for a number with three wrong birth dates in the app; in the dashboard open the child → "ربط بحساب ولي الأمر" → confirm; the app shows the children. For a guardian locked out of re-verification, open one of their children → "فك قفل التحقق" → confirm.

Automated: `flutter test`, `cd functions && npm test && npm run test:rules`, `scripts/dashboard_e2e.sh`.
