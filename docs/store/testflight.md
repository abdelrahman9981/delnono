# iOS: first TestFlight build (internal testing)

Version **1.0.0 (1)**, bundle id **eg.drelnono.app**, name «دكتور النونو», real project
dr-elnono-clinic (`FIREBASE_ENV=prod`). Internal testing only: no App Store review.

## What is set in the project

- Automatic signing; **Development Team: chosen by the owner in Xcode** (step 1 below).
- Push Notifications capability (`Runner.entitlements`, `aps-environment`) and the
  `remote-notification` background mode.
- `ITSAppUsesNonExemptEncryption = NO` (standard HTTPS only), so no export-compliance question.
- Arabic: `CFBundleDevelopmentRegion = ar`, `CFBundleLocalizations = [ar]`. No usage-description
  strings are needed: the app uses no camera, photos, location, contacts, microphone or tracking;
  notifications use the system prompt.
- `PrivacyInfo.xcprivacy` (UserDefaults CA92.1, FileTimestamp C617.1; name, phone number, health data
  linked, app functionality, no tracking). Plugins and Firebase ship their own manifests.
- App icons without alpha (all 21 checked); launch screen `LaunchScreen.storyboard`.
- The D-51 code swap (123456 for any number) is not in release builds: the build script checks the
  compiled code (0 matches; an emulator build has 4) and `test/features/auth/dev_otp_release_test.dart`.

## Steps for the owner

1. **Team (once).** `open ios/Runner.xcworkspace` → in the navigator click **Runner** (blue icon) →
   TARGETS **Runner** → **Signing & Capabilities** → tick **Automatically manage signing** → **Team**:
   choose your team (the paid Apple Developer Program team, not "Personal Team"). Xcode creates the
   certificate and profile. If it says the bundle id is taken, the id must be registered under your
   team at developer.apple.com → Certificates, IDs & Profiles → Identifiers → **+** → App IDs →
   Bundle ID `eg.drelnono.app`, capability **Push Notifications**.
2. **App record (once).** appstoreconnect.apple.com → **Apps** → **+** → **New App** → iOS, name
   «دكتور النونو», primary language **Arabic**, bundle id **eg.drelnono.app**, SKU `drelnono-ios`.
3. **Build.** `scripts/build_ios_release.sh` (archives to `build/ios/archive/Runner.xcarchive` and
   checks the binary).
4. **Upload.** `open build/ios/archive/Runner.xcarchive` (Xcode Organizer) → select the archive →
   **Distribute App** → **App Store Connect** → **Upload** → keep the defaults (automatic signing,
   upload symbols) → **Upload**.
5. **Testers.** App Store Connect → the app → **TestFlight** → wait for processing (≈15–30 min) →
   **Internal Testing** → **+** group → add testers (App Store Connect users) → they install from the
   TestFlight app.

Next builds: `BUILD_NUMBER=2 scripts/build_ios_release.sh` (the build number must go up each upload).

## Known limits of this build

- **Booking, registration, linking children, changing the number, deleting the account and every
  dashboard action need Cloud Functions**, which are not deployed: dr-elnono-clinic is on the Spark
  plan and the deploy was refused (billing account not open, BRD D-40). Browsing Home, «محتوى»,
  signing in with a test number and reading seeded records work.
- **Server push needs the APNs key** uploaded in Firebase → Project settings → Cloud Messaging
  (later). Local appointment and vaccine reminders work without it.
- **Phone sign-in** works with the console test numbers (code 123456); real SMS is limited to 10 a day
  on Spark.
- Demo data and medical texts are proposed placeholders until the doctor approves them.
