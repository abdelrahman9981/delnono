# Client demo plan

Steps to take the app from the emulators to a demo the clinic owner can try. Decisions: BRD D-38 to
D-43. Until step 1, everything runs on the Firebase emulators (`demo-delnono`).

Firebase project: `dr-elnono-clinic` (Android and iOS apps registered as `eg.drelnono.app`; the app
uses it only when built with `--dart-define=FIREBASE_ENV=prod`).

## Status (27 Oct 2026, D-53)

Done by the owner in the Firebase console:

- [x] Firestore created on `dr-elnono-clinic`: Standard edition, `(default)` database, location
      **me-central1 (Doha)**, production-mode rules for now. The location is permanent.
- [x] Phone sign-in enabled (Spark plan; real SMS limited to 10 a day).
- [x] Test numbers +201000000001, +201000000003, +201000000099 with code 123456.

Remaining (deploys only with the owner's approval):

- [ ] Blaze + 1 USD budget alert (step 1).
- [ ] Switch the Functions region to `me-central1` in `functions/src/lib/region.ts` and
      `lib/core/firebase/functions_region.dart` (both still `us-central1` for the emulators), then
      deploy rules, indexes, functions and hosting (steps 4 and 8).
- [ ] Apple: APNs key and TestFlight, later (steps 3 and 6).
- [ ] Launch checklist: no proposed medical content in production (docs/launch-checklist.md).

## 1. Blaze and budget alert (2–3 days before the demo, D-40)

- [ ] Upgrade `dr-elnono-clinic` to the Blaze plan (billing account owned by the clinic).
- [ ] Add a budget of 1 USD with alerts at 50%, 90% and 100%, sent to the owner and the developer.
- [ ] Confirm the APIs Firebase asks for (Cloud Functions, Cloud Build, Artifact Registry).

## 2. Firestore region

- [x] Create the Firestore database: me-central1 (Doha), done by the owner (D-53). The region
      cannot be changed later.
- [ ] Set the Functions region (me-central1) in `functions/src/lib/region.ts` and `lib/core/firebase/functions_region.dart`
      to match (research R8 of 001).

## 3. Test phone numbers (D-41)

- [x] In Authentication → Sign-in method → Phone, enable phone sign-in and add the test numbers with
      fixed codes (done by the owner, D-53):

  | Number | Code | Use |
  |--------|------|-----|
  | +20 100 000 0001 | 123456 | the registered family (signs in to Home, children linked) |
  | +20 100 000 0003 | 123456 | a clinic family to link (birth date 2023-05-10) |
  | +20 100 000 0099 | 123456 | a new guardian |

  Only these console test numbers use 123456 on the real project; there is no bypass for real
  numbers (D-51). On the emulators, 123456 works for any number through a development helper that
  production builds do not contain.

- [ ] Do not send real SMS for the demo.
- [ ] Add the Android SHA-1 and SHA-256 fingerprints and the Apple push key (APNs) so phone sign-in
      works on devices.
- [ ] Restrict the API keys in Google Cloud (Android package and SHA, iOS bundle id).

## 4. Deploy rules and functions

- [ ] `firebase deploy --only firestore:rules,firestore:indexes --project prod`
- [ ] `firebase deploy --only functions --project prod`
- [ ] Load the clinic settings and the placeholder lists (seed script adapted to the real project,
      run once by the developer; never the emulator export).
- [ ] Create the doctor's staff account (feature 005).

## 5. Android APK

- [ ] `flutter build apk --release --dart-define=FIREBASE_ENV=prod`
- [ ] Sign with the release key (kept outside the repository) and share the APK link.

## 6. iOS TestFlight (once the Apple developer account is ready)

- [ ] App Store Connect record for `eg.drelnono.app`.
- [ ] `flutter build ipa --dart-define=FIREBASE_ENV=prod`, upload with Transporter or Xcode.
- [ ] Add the owner and staff as TestFlight testers.

## 7. After the demo: real SMS codes (D-52)

- [ ] Codes are sent by SMS through Firebase Phone Auth on `dr-elnono-clinic` (needs Blaze). No
      WhatsApp OTP. The test numbers above stay for store review and demos.

## 8. Web demo link (D-43)

- [ ] After the app is complete, build the demo version with sample data and no backend.
- [ ] Deploy it to Firebase Hosting and share the link.

## Reminders (D-42)

Phase 1 reminders are local notifications scheduled on the phone when a booking is made or changed,
and cancelled when it is cancelled (feature 007). Server push waits for Blaze.
