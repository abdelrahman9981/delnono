import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// Places taken per hour at a clinic on a date (`slots`, counts only), live (research R6; 004 R2).
final slotsTakenProvider = StreamProvider.family<Map<int, int>, ({String clinicId, String date})>((ref, key) => ref
    .watch(firestoreProvider)
    .collection('slots')
    .where('clinicId', isEqualTo: key.clinicId)
    .where('date', isEqualTo: key.date)
    .snapshots()
    .map((q) => {for (final d in q.docs) (d['hour'] as num).toInt(): (d['taken'] as num).toInt()}));
