import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/domain/clinic_time.dart';
import '../domain/family_package.dart';

/// The signed-in family's packages, with ids (renewals and the expiry reminder need them).
final familyPackageListProvider = StreamProvider<List<FamilyPackage>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('packages')
      .where('guardianUid', isEqualTo: uid)
      .snapshots()
      .map((q) => [
            for (final d in q.docs)
              if (d.data()['startsOn'] is String && d.data()['endsOn'] is String)
                FamilyPackage(
                  id: d.id,
                  active: d.data()['active'] == true,
                  startsOn: d.data()['startsOn'] as String,
                  endsOn: d.data()['endsOn'] as String,
                  soldAtClinicId: d.data()['soldAtClinicId'] as String?,
                ),
          ]);
});

/// The family's packages as of today (Cairo).
final familyPackageViewProvider = Provider<FamilyPackageView>((ref) => familyPackageView(
      ref.watch(familyPackageListProvider).value ?? const [],
      ClinicTime.dateOf(ref.watch(clockProvider)()),
    ));
