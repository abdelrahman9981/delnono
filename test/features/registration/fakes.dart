import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:mocktail/mocktail.dart';

class FakeRegistrationApi implements RegistrationApi {
  final registrations = <(GuardianDetails, int)>[];
  final acceptedVersions = <int>[];
  Object? error;
  bool hasClinicChildren = false;

  @override
  Future<bool> completeRegistration(GuardianDetails details, int policyVersion) async {
    if (error != null) throw error!;
    registrations.add((details, policyVersion));
    return hasClinicChildren;
  }

  @override
  Future<void> acceptPolicy(int policyVersion) async {
    if (error != null) throw error!;
    acceptedVersions.add(policyVersion);
  }
}

class FakeChildrenRepository extends Mock implements ChildrenRepository {
  final created = <NewChild>[];
  Object? error;

  @override
  Future<String> createChild(NewChild child) async {
    if (error != null) throw error!;
    created.add(child);
    return 'child-${created.length}';
  }
}
