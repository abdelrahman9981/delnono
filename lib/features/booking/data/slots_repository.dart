import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// Places taken per hour on a date (`slots`, counts only), live (research R6).
final slotsTakenProvider = StreamProvider.family<Map<int, int>, String>((ref, date) => ref
    .watch(firestoreProvider)
    .collection('slots')
    .where('date', isEqualTo: date)
    .snapshots()
    .map((q) => {for (final d in q.docs) (d['hour'] as num).toInt(): (d['taken'] as num).toInt()}));
