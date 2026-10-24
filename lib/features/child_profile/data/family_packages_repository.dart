import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';

/// The family's packages (`packages/{id}`, created by feature 006), read only (FR-020).
final familyPackagesProvider = StreamProvider<List<({bool active, String startsOn, String endsOn})>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
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
