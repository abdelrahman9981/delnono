import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/functions_region.dart';
import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';

enum Sex { male, female }

/// `children/{childId}` (data-model.md). Created only by Cloud Functions.
class Child {
  const Child({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    this.birthWeightKg,
    this.allergies,
  });

  factory Child.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return Child(
      id: snap.id,
      name: d['name'] as String,
      birthDate: d['birthDate'] as String,
      sex: d['sex'] == 'female' ? Sex.female : Sex.male,
      birthWeightKg: (d['birthWeightKg'] as num?)?.toDouble(),
      allergies: d['allergies'] as String?,
    );
  }

  final String id;
  final String name;

  /// `YYYY-MM-DD`.
  final String birthDate;
  final Sex sex;
  final double? birthWeightKg;
  final String? allergies;
}

/// What a guardian enters for a new child (data-model.md constraints are checked on the server).
class NewChild {
  const NewChild({
    required this.name,
    required this.birthDate,
    required this.sex,
    this.birthWeightKg,
    this.allergies,
  });

  final String name;

  /// `YYYY-MM-DD`.
  final String birthDate;
  final Sex sex;
  final double? birthWeightKg;
  final String? allergies;
}

/// `createChild` refused: a child with this name and birth date is already on the number (FR-022).
class DuplicateChildException implements Exception {
  const DuplicateChildException({required this.existingLinked});

  /// True when the existing child is already in this account; false when the clinic (or an earlier
  /// account) registered it and the guardian should contact the clinic.
  final bool existingLinked;
}

class ChildrenRepository {
  ChildrenRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<Child>> watchLinked(String uid) => _db
      .collection('children')
      .where('guardianUid', isEqualTo: uid)
      .snapshots()
      .map((q) => q.docs.map(Child.fromSnapshot).toList());

  /// Creates a child through the `createChild` function, which checks for duplicates.
  /// Throws [DuplicateChildException] for FR-022, or the function's error otherwise.
  Future<String> createChild(NewChild child) async {
    try {
      final result = await _functions.httpsCallable('createChild').call<Map<String, dynamic>>({
        'name': child.name,
        'birthDate': child.birthDate,
        'sex': child.sex.name,
        if (child.birthWeightKg != null) 'birthWeightKg': child.birthWeightKg,
        if (child.allergies != null) 'allergies': child.allergies,
      });
      return result.data['childId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        final details = e.details;
        throw DuplicateChildException(
          existingLinked: details is Map && details['existingLinked'] == true,
        );
      }
      rethrow;
    }
  }
}

final childrenRepositoryProvider = Provider<ChildrenRepository>(
  (ref) => ChildrenRepository(ref.watch(firestoreProvider), ref.watch(functionsProvider)),
);

/// Children linked to the signed-in guardian; empty when signed out.
final childrenProvider = StreamProvider<List<Child>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(childrenRepositoryProvider).watchLinked(uid);
});
