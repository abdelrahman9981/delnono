import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/session_flags.dart';
import '../../booking/data/bookings_repository.dart';
import '../../child_profile/data/family_packages_repository.dart';
import '../../children/data/children_repository.dart';
import '../../packages/data/packages_repository.dart';
import '../data/session_api.dart';

/// Runs `touchSession` once per app start for the signed-in guardian and raises the re-check flag
/// that drives guard step 3a (FR-010a). Offline or failed checks are skipped and retried on the
/// next start; the rules keep child data closed on the server either way.
class SessionController extends Notifier<String?> {
  /// The uid already checked in this app session.
  @override
  String? build() => null;

  Future<void> check(String uid) async {
    if (state == uid) return;
    state = uid;
    try {
      final required = await ref.read(sessionApiProvider).touchSession();
      // The app may have been torn down while the call was out (tests, hot restart).
      if (!ref.mounted) return;
      ref.read(reverifyRequiredProvider.notifier).set(required);
    } catch (_) {
      if (ref.mounted) state = null;
    }
  }

  /// The birth-date re-check passed: lift the flag and reload the family data the rules had refused.
  void reverified() {
    ref.read(reverifyRequiredProvider.notifier).set(false);
    ref.invalidate(childrenProvider);
    ref.invalidate(myBookingsProvider);
    ref.invalidate(familyPackagesProvider);
    ref.invalidate(familyPackageListProvider);
  }

  /// Signed out: the next guardian on this device is checked again.
  void reset() {
    state = null;
    ref.read(reverifyRequiredProvider.notifier).set(false);
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, String?>(SessionController.new);
