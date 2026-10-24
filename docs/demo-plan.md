# Client demo plan

Steps to take the app from the emulators to a demo the clinic owner can try. Decisions: BRD D-38 to
D-43. Until step 1, everything runs on the Firebase emulators (`demo-delnono`).

Firebase project: `dr-elnono-clinic` (Android and iOS apps registered as `eg.drelnono.app`; the app
uses it only when built with `--dart-define=FIREBASE_ENV=prod`).

## 1. Blaze and budget alert (2–3 days before the demo, D-40)

- [ ] Upgrade `dr-elnono-clinic` to the Blaze plan (billing account owned by the clinic).
- [ ] Add a budget of 1 USD with alerts at 50%, 90% and 100%, sent to the owner and the developer.
- [ ] Confirm the APIs Firebase asks for (Cloud Functions, Cloud Build, Artifact Registry).

## 2. Firestore region

- [ ] Create the Firestore database in the region chosen after the legal review (Law 151/2020). The
      region cannot be changed later.
- [ ] Set the Functions region in `functions/src/lib/region.ts` and `lib/core/firebase/functions_region.dart`
      to match (research R8 of 001).

## 3. Test phone numbers (D-41)

- [ ] In Authentication → Sign-in method → Phone, enable phone sign-in and add the test numbers with
      fixed codes, for example:

  | Number | Code | Use |
  |--------|------|-----|
  | +20 100 000 0001 | 123456 | the seeded clinic family (linked children) |
  | +20 100 000 0099 | 123456 | a new guardian |

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

## 7. Web demo link (D-43)

- [ ] After the app is complete, build the demo version with sample data and no backend.
- [ ] Deploy it to Firebase Hosting and share the link.

## Reminders (D-42)

Phase 1 reminders are local notifications scheduled on the phone when a booking is made or changed,
and cancelled when it is cancelled (feature 007). Server push waits for Blaze.
