import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/functions_region.dart';
import 'guardian_repository.dart';

/// Guardian details typed during first-run registration. Held in memory until consent (FR-015).
class GuardianDetails {
  const GuardianDetails({required this.fullName, required this.relation, this.email});

  final String fullName;
  final Relation relation;
  final String? email;
}

const consentScopes = ['privacy_policy', 'terms', 'child_data'];

class LinkedChild {
  const LinkedChild(this.childId, this.name);

  final String childId;
  final String name;
}

/// `linkClinicChildren`: the birth date matched none of the children; [remaining] tries are left.
class LinkWrongBirthDate implements Exception {
  const LinkWrongBirthDate(this.remaining);

  final int remaining;
}

/// `linkClinicChildren`: locked after too many wrong dates; the clinic links the children (FR-021a).
class LinkLocked implements Exception {
  const LinkLocked();
}

/// `linkClinicChildren`: no unlinked children are left on the number.
class LinkNothingToLink implements Exception {
  const LinkNothingToLink();
}

/// Registration callables (contracts/callables.md).
abstract interface class RegistrationApi {
  /// Writes guardian and consent together. Returns whether unlinked children exist on the number.
  Future<bool> completeRegistration(GuardianDetails details, int policyVersion);

  /// Records consent to a new policy version (FR-017).
  Future<void> acceptPolicy(int policyVersion);

  /// Links the clinic's children on this number if [birthDate] (`YYYY-MM-DD`) matches one (FR-021).
  /// Throws [LinkWrongBirthDate], [LinkLocked] or [LinkNothingToLink].
  Future<List<LinkedChild>> linkClinicChildren(String birthDate);
}

class FirebaseRegistrationApi implements RegistrationApi {
  FirebaseRegistrationApi(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<bool> completeRegistration(GuardianDetails details, int policyVersion) async {
    final result = await _functions.httpsCallable('completeRegistration').call<Map<String, dynamic>>({
      'fullName': details.fullName,
      'relation': details.relation.name,
      if (details.email != null) 'email': details.email,
      'consent': {'policyVersion': policyVersion, 'scopes': consentScopes},
    });
    return result.data['hasClinicChildren'] == true;
  }

  @override
  Future<void> acceptPolicy(int policyVersion) => _functions
      .httpsCallable('acceptPolicy')
      .call<Object?>({'policyVersion': policyVersion, 'scopes': consentScopes});

  @override
  Future<List<LinkedChild>> linkClinicChildren(String birthDate) async {
    try {
      final result =
          await _functions.httpsCallable('linkClinicChildren').call<Map<String, dynamic>>({'birthDate': birthDate});
      return [
        for (final c in (result.data['linked'] as List).cast<Map<Object?, Object?>>())
          LinkedChild(c['childId'] as String, c['name'] as String),
      ];
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          final details = e.details;
          final remaining = details is Map ? details['remaining'] : null;
          throw LinkWrongBirthDate(remaining is num ? remaining.toInt() : 0);
        case 'resource-exhausted':
          throw const LinkLocked();
        case 'not-found':
          throw const LinkNothingToLink();
      }
      rethrow;
    }
  }
}

final registrationApiProvider =
    Provider<RegistrationApi>((ref) => FirebaseRegistrationApi(ref.watch(functionsProvider)));
