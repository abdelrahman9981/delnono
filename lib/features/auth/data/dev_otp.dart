import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_init.dart';
import '../../../core/net/get_text.dart';

/// The code that signs in during development (BRD D-51): in emulator builds, typing it signs in any
/// number. On the real project only the console's test numbers (D-41) use it; there is no bypass
/// for real numbers there, because no resolver exists outside emulator builds.
const devFixedCode = '123456';

/// Finds the real code the Auth emulator issued for a number (the emulator never sends SMS).
abstract interface class DevCodeResolver {
  Future<String?> realCodeFor(String phoneE164);
}

/// Reads `/emulator/v1/projects/demo-delnono/verificationCodes` from the Auth emulator.
class EmulatorCodeResolver implements DevCodeResolver {
  const EmulatorCodeResolver();

  @override
  Future<String?> realCodeFor(String phoneE164) async {
    // The Android emulator reaches the host machine through 10.0.2.2.
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    try {
      final text = await getText(Uri.parse('http://$host:9099/emulator/v1/projects/demo-delnono/verificationCodes'));
      final body = jsonDecode(text) as Map<String, dynamic>;
      final codes = (body['verificationCodes'] as List? ?? const []).cast<Map<String, dynamic>>();
      return codes.lastWhere((c) => c['phoneNumber'] == phoneE164, orElse: () => const {})['code'] as String?;
    } catch (_) {
      return null;
    }
  }
}

/// The resolver for a build: only emulator builds of the demo project get one (phone or web); prod
/// builds never, and the web demo on dr-elnono-clinic is a prod build.
DevCodeResolver? devCodeResolverFor({required bool emulator, required bool prod}) =>
    emulator && !prod ? const EmulatorCodeResolver() : null;

/// Decided by compile-time constants, so release builds drop the resolver's code entirely
/// (scripts/build_ios_release.sh and scripts/build_web_demo.sh check the binaries).
final devCodeResolverProvider = Provider<DevCodeResolver?>(
  (ref) => useEmulator && !useProdFirebase ? const EmulatorCodeResolver() : null,
);
