import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options for the emulator-only project `demo-delnono`.
///
/// The `demo-` prefix means every Firebase call goes to the local emulators; the values below are
/// not real credentials. Replace this file with the output of `flutterfire configure` once the
/// real Firebase project exists (functions/README.md).
class DefaultFirebaseOptions {
  /// Not a real key. It only has the shape iOS checks for (39 characters starting with `AIza`);
  /// `demo-api-key` makes FirebaseInstallations throw at startup on iOS.
  static const _demoApiKey = 'AIzaDemoKeyForLocalEmulatorsOnly0000000';

  static FirebaseOptions get currentPlatform {
    // The clinic dashboard (005) runs in the browser.
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _ios;
      default:
        return _android;
    }
  }

  static const _android = FirebaseOptions(
    apiKey: _demoApiKey,
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-delnono',
  );

  static const _ios = FirebaseOptions(
    apiKey: _demoApiKey,
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-delnono',
    iosBundleId: 'eg.drelnono.app',
  );

  static const _web = FirebaseOptions(
    apiKey: _demoApiKey,
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-delnono',
    authDomain: 'demo-delnono.firebaseapp.com',
  );
}
