import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ChildrenRepository {
  ChildrenRepository(this._db);

  final FirebaseFirestore _db;

  Stream<List<Child>> watchLinked(String uid) => _db
      .collection('children')
      .where('guardianUid', isEqualTo: uid)
      .snapshots()
      .map((q) => q.docs.map(Child.fromSnapshot).toList());
}

final childrenRepositoryProvider =
    Provider<ChildrenRepository>((ref) => ChildrenRepository(ref.watch(firestoreProvider)));

/// Children linked to the signed-in guardian; empty when signed out.
final childrenProvider = StreamProvider<List<Child>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(childrenRepositoryProvider).watchLinked(uid);
});
