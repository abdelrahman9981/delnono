import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// `children/{id}/doses/{d}`: a vaccine dose given (data-model.md). Recorded by staff (004).
class DoseRecord {
  const DoseRecord({
    required this.id,
    required this.vaccineId,
    required this.dose,
    required this.givenOn,
    this.scheduleId,
    this.lot,
    this.visitId,
  });

  factory DoseRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    final lot = (d['lot'] as String?)?.trim();
    return DoseRecord(
      id: s.id,
      scheduleId: d['scheduleId'] as String?,
      vaccineId: d['vaccineId'] as String,
      dose: (d['dose'] as num?)?.toInt() ?? 1,
      givenOn: d['givenOn'] as String,
      lot: lot == null || lot.isEmpty ? null : lot,
      visitId: d['visitId'] as String?,
    );
  }

  final String id;

  /// The basic schedule entry; null for additional vaccines.
  final String? scheduleId;
  final String vaccineId;
  final int dose;

  /// `YYYY-MM-DD`.
  final String givenOn;
  final String? lot;
  final String? visitId;
}

/// A child's recorded doses, oldest first.
final dosesProvider = StreamProvider.family<List<DoseRecord>, String>(
  (ref, childId) => ref
      .watch(firestoreProvider)
      .collection('children/$childId/doses')
      .snapshots()
      .map((q) => q.docs.map(DoseRecord.fromSnapshot).toList()..sort((a, b) => a.givenOn.compareTo(b.givenOn))),
);
