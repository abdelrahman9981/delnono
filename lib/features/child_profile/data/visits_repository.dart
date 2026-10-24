import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

enum VisitType { clinic, vaccine, walkIn }

/// `children/{id}/visits/{v}` (data-model.md). Created by staff (004). The doctor's notes are in a
/// staff-only document and never reach the app (clarification Q1). Prescription photos are Phase 2 (D-39).
class Visit {
  const Visit({required this.id, required this.date, required this.type});

  factory Visit.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return Visit(
      id: s.id,
      date: d['date'] as String,
      type: switch (d['type']) {
        'vaccine' => VisitType.vaccine,
        'walkIn' => VisitType.walkIn,
        _ => VisitType.clinic,
      },
    );
  }

  final String id;

  /// `YYYY-MM-DD`.
  final String date;
  final VisitType type;
}

/// A child's visits, newest first.
final visitsProvider = StreamProvider.family<List<Visit>, String>(
  (ref, childId) => ref
      .watch(firestoreProvider)
      .collection('children/$childId/visits')
      .snapshots()
      .map((q) => q.docs.map(Visit.fromSnapshot).toList()..sort((a, b) => b.date.compareTo(a.date))),
);
