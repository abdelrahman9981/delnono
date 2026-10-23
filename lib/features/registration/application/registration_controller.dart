import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/session_flags.dart';
import '../data/registration_api.dart';

@immutable
class RegistrationState {
  const RegistrationState({this.details, this.submitting = false, this.error});

  /// Typed on the guardian details screen; never stored before consent (FR-015).
  final GuardianDetails? details;
  final bool submitting;
  final Object? error;
}

/// First-run registration: guardian details → consent → first child (FR-012). Also records
/// re-consent when the policy version changes (FR-017).
class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  RegistrationApi get _api => ref.read(registrationApiProvider);

  /// Keeps [details] in memory and marks registration as in progress, so the guard asks for the
  /// first child once consent is recorded (contracts/routes.md, step 5).
  void setDetails(GuardianDetails details) {
    state = RegistrationState(details: details);
    ref.read(registrationInProgressProvider.notifier).set(true);
  }

  /// Sends details and consent together. Returns true on success.
  Future<bool> consentAndRegister(int policyVersion) async {
    final details = state.details;
    if (details == null || state.submitting) return false;
    state = RegistrationState(details: details, submitting: true);
    try {
      await _api.completeRegistration(details, policyVersion);
      state = const RegistrationState();
      return true;
    } catch (e) {
      state = RegistrationState(details: details, error: e);
      return false;
    }
  }

  /// Records consent to a new policy version for an existing guardian. Returns true on success.
  Future<bool> acceptPolicy(int policyVersion) async {
    if (state.submitting) return false;
    state = const RegistrationState(submitting: true);
    try {
      await _api.acceptPolicy(policyVersion);
      state = const RegistrationState();
      return true;
    } catch (e) {
      state = RegistrationState(error: e);
      return false;
    }
  }

  /// The first child was added or linked, or the guardian left the flow.
  void finish() {
    state = const RegistrationState();
    ref.read(registrationInProgressProvider.notifier).set(false);
  }
}

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(RegistrationController.new);
