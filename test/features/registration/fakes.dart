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

  final linkAttempts = <String>[];

  /// What the next [linkClinicChildren] call does: a list to return, or an exception to throw.
  Object linkResult = const <LinkedChild>[];

  @override
  Future<List<LinkedChild>> linkClinicChildren(String birthDate) async {
    linkAttempts.add(birthDate);
    final r = linkResult;
    if (r is Exception) throw r;
    return r as List<LinkedChild>;
  }
}

class FakeChildrenRepository extends Mock implements ChildrenRepository {
  final created = <NewChild>[];
  final updates = <({String childId, String uid, String name, String? allergies})>[];
  Object? error;

  @override
  Future<void> updateDetails(String childId, {required String uid, required String name, String? allergies}) async {
    if (error != null) throw error!;
    updates.add((childId: childId, uid: uid, name: name, allergies: allergies));
  }

  @override
  Future<String> createChild(NewChild child) async {
    if (error != null) throw error!;
    created.add(child);
    return 'child-${created.length}';
  }
}
