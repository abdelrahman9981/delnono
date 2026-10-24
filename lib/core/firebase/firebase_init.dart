import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'firebase_options_prod.dart';
import 'functions_region.dart';

/// Set with `--dart-define=USE_EMULATOR=true` to use the local Firebase Emulator Suite.
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// `--dart-define=FIREBASE_ENV=prod` selects the real project `dr-elnono-clinic`. Anything else
/// (the default) uses the emulator-only `demo-delnono` project, so development and tests can never
/// reach real data.
const firebaseEnv = String.fromEnvironment('FIREBASE_ENV', defaultValue: 'demo');
const useProdFirebase = firebaseEnv == 'prod';

FirebaseOptions get firebaseOptions =>
    useProdFirebase ? ProdFirebaseOptions.currentPlatform : DefaultFirebaseOptions.currentPlatform;

Future<void> initFirebase() async {
  if (useProdFirebase && useEmulator) {
    throw StateError('FIREBASE_ENV=prod cannot be combined with USE_EMULATOR=true.');
  }
  await Firebase.initializeApp(options: firebaseOptions);

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
    FirebaseFunctions.instanceFor(region: functionsRegion).useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
}
