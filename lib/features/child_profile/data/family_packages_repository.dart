import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../registration/data/family_access.dart';

/// The family's packages (`packages/{id}`, created by feature 006), read only (FR-020).
final familyPackagesProvider = StreamProvider<List<({bool active, String startsOn, String endsOn})>>((ref) {
  // Only once the rules allow it, and again whenever that changes (bug 0003).
  final uid = ref.watch(familyAccessProvider);
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('packages')
      .where('guardianUid', isEqualTo: uid)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            if (d.data()['startsOn'] is String && d.data()['endsOn'] is String)
              (
                active: d.data()['active'] as bool? ?? false,
                startsOn: d.data()['startsOn'] as String,
                endsOn: d.data()['endsOn'] as String,
              ),
        ],
      );
});
