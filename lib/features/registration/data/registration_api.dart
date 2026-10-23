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

/// Registration callables (contracts/callables.md).
abstract interface class RegistrationApi {
  /// Writes guardian and consent together. Returns whether unlinked children exist on the number.
  Future<bool> completeRegistration(GuardianDetails details, int policyVersion);

  /// Records consent to a new policy version (FR-017).
  Future<void> acceptPolicy(int policyVersion);
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
}

final registrationApiProvider =
    Provider<RegistrationApi>((ref) => FirebaseRegistrationApi(ref.watch(functionsProvider)));
