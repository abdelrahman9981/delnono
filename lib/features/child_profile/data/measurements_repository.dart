import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// `children/{id}/measurements/{m}` (data-model.md). Recorded by staff (004); read only here.
class Measurement {
  const Measurement({
    required this.id,
    required this.measuredOn,
    this.weightKg,
    this.lengthCm,
    this.headCm,
    this.visitId,
  });

  factory Measurement.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return Measurement(
      id: s.id,
      measuredOn: d['measuredOn'] as String,
      weightKg: (d['weightKg'] as num?)?.toDouble(),
      lengthCm: (d['lengthCm'] as num?)?.toDouble(),
      headCm: (d['headCm'] as num?)?.toDouble(),
      visitId: d['visitId'] as String?,
    );
  }

  final String id;

  /// `YYYY-MM-DD`.
  final String measuredOn;
  final double? weightKg;
  final double? lengthCm;
  final double? headCm;
  final String? visitId;
}

/// A child's measurements, oldest first.
final measurementsProvider = StreamProvider.family<List<Measurement>, String>(
  (ref, childId) => ref
      .watch(firestoreProvider)
      .collection('children/$childId/measurements')
      .snapshots()
      .map((q) => q.docs.map(Measurement.fromSnapshot).toList()..sort((a, b) => a.measuredOn.compareTo(b.measuredOn))),
);
