import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options for the real project `dr-elnono-clinic`, used only when the app is built with
/// `--dart-define=FIREBASE_ENV=prod` (see firebase_init.dart). Development and every test use the
/// emulator-only `demo-delnono` options in firebase_options.dart.
///
/// These are client identifiers, not secrets (Firebase documents them as safe to ship in apps);
/// access is controlled by Security Rules. Values come from the apps registered on 2026-10-24:
/// Android 1:689130598694:android:8a92e9b74ca1b5117d11e7, iOS 1:689130598694:ios:8479a72b2f171b3a7d11e7.
class ProdFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // First: in a browser, defaultTargetPlatform is the phone's OS (Safari on an iPhone says iOS).
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('dr-elnono-clinic is configured for Android, iOS and the web only.');
    }
  }

  // The web demo (D-43): the Web app registered in the console (docs/demo-runbook.md). Its app id and
  // API key are passed at build time by scripts/build_web_demo.sh until they are known; like the
  // others they are public identifiers, not secrets.
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');

  static FirebaseOptions get web {
    if (_webAppId.isEmpty || _webApiKey.isEmpty) {
      throw UnsupportedError('Build the web demo with scripts/build_web_demo.sh (needs the Web app config).');
    }
    return const FirebaseOptions(
      apiKey: _webApiKey,
      appId: _webAppId,
      messagingSenderId: '689130598694',
      projectId: 'dr-elnono-clinic',
      authDomain: 'dr-elnono-clinic.firebaseapp.com',
      storageBucket: 'dr-elnono-clinic.firebasestorage.app',
    );
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCS7FyIdNwC35snyYjXF_yfohNMkdykbMI',
    appId: '1:689130598694:android:8a92e9b74ca1b5117d11e7',
    messagingSenderId: '689130598694',
    projectId: 'dr-elnono-clinic',
    storageBucket: 'dr-elnono-clinic.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDshBsqrgSePH0YXUVE3pdiNQYzvEcMRcA',
    appId: '1:689130598694:ios:8479a72b2f171b3a7d11e7',
    messagingSenderId: '689130598694',
    projectId: 'dr-elnono-clinic',
    storageBucket: 'dr-elnono-clinic.firebasestorage.app',
    iosBundleId: 'eg.drelnono.app',
  );
}
