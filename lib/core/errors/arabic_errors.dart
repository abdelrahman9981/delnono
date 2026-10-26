import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/l10n/app_localizations.dart';

/// Arabic message for an error from Firebase Auth or a callable (contracts/callables.md).
///
/// Screens that give a code a more specific meaning (for example `already-exists` from
/// `createChild` is the duplicate-child warning) handle that code themselves before calling this.
String arabicErrorMessage(Object error, AppLocalizations l10n) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-verification-code' => l10n.errInvalidCode,
      'session-expired' => l10n.errCodeExpired,
      'too-many-requests' => l10n.errTooManyRequests,
      'network-request-failed' => l10n.errNoConnection,
      'credential-already-in-use' => l10n.errNumberInUse,
      'quota-exceeded' => l10n.errSmsQuota,
      _ => l10n.errGeneric,
    };
  }
  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => l10n.errNoConnection,
      'unauthenticated' => l10n.errUnauthenticated,
      'already-exists' => l10n.errAlreadyExists,
      'failed-precondition' => l10n.errPolicyOutdated,
      'invalid-argument' => l10n.errInvalidInput,
      'not-found' => l10n.errNoClinicChildren,
      'permission-denied' => l10n.errBirthDateMismatch,
      'resource-exhausted' => l10n.errLocked,
      _ => l10n.errGeneric,
    };
  }
  if (error is TimeoutException) return l10n.errTimeout;
  return l10n.errGeneric;
}
