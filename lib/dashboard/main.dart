import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/firebase_init.dart';
import 'app.dart';

/// The clinic dashboard (005), a second entry point of this project for the web:
/// `flutter run -d chrome -t lib/dashboard/main.dart --dart-define=USE_EMULATOR=true`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No offline copy in the browser: staff computers may be shared (research R1).
  await initFirebase(persistence: false);
  runApp(const ProviderScope(child: DashboardApp()));
}
