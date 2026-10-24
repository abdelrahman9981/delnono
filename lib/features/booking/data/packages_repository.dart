import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';

/// Id of the family's active package covering [date] (`YYYY-MM-DD`), or null (FR-016). Packages are
/// created by feature 006; the server decides the price, this only drives the summary.
final activePackageProvider = StreamProvider.family<String?, String>((ref, date) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('packages')
      .where('guardianUid', isEqualTo: uid)
      .where('active', isEqualTo: true)
      .snapshots()
      .map((q) {
    for (final d in q.docs) {
      final from = d.data()['startsOn'] as String? ?? '';
      final to = d.data()['endsOn'] as String? ?? '';
      if (from.compareTo(date) <= 0 && date.compareTo(to) <= 0) return d.id;
    }
    return null;
  });
});
