import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import 'guardian_repository.dart';

/// The signed-in guardian's uid once the rules let them read family data (a guardian doc with the
/// current policy consented), or null before that.
///
/// Family queries (children, bookings, packages) start from this instead of the sign-in alone. A
/// listener started before registration and consent is denied, Riverpod gives up retrying after a
/// while, and the screens would show nothing even after linking succeeded (bug 0003, 26 Oct 2026).
/// Waiting for access, and restarting when it changes, fixes that.
final familyAccessProvider = Provider<String?>((ref) {
  final guardian = ref.watch(guardianProvider).value;
  final current = ref.watch(policySettingsProvider).value?.currentVersion;
  if (guardian == null || current == null || guardian.consentVersion < current) return null;
  return guardian.uid;
});
