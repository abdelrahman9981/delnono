import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Set with `--dart-define=USE_EMULATOR=true` to use the local Firebase Emulator Suite.
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Child profile and loaded content stay readable offline (constitution Principle VII).
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  if (useEmulator) {
    // The Android emulator reaches the host machine through 10.0.2.2.
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    // The emulator issues codes itself; skip APNs/reCAPTCHA app checks, which a demo project cannot
    // pass. Never set outside the emulator.
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }
}
