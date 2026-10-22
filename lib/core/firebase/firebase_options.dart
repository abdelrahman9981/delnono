import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options for the emulator-only project `demo-delnono`.
///
/// The `demo-` prefix means every Firebase call goes to the local emulators; the values below are
/// not real credentials. Replace this file with the output of `flutterfire configure` once the
/// real Firebase project exists (functions/README.md).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _ios;
      default:
        return _android;
    }
  }

  static const _android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-delnono',
  );

  static const _ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-delnono',
    iosBundleId: 'com.example.delnono',
  );
}
