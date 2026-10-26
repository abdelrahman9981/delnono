import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../domain/booking.dart';
import '../../registration/data/family_access.dart';

/// The signed-in guardian's bookings, soonest first.
final myBookingsProvider = StreamProvider<List<Booking>>((ref) {
  // Only once the rules allow it, and again whenever that changes (bug 0003).
  final uid = ref.watch(familyAccessProvider);
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('guardianUid', isEqualTo: uid)
      .orderBy('startsAt')
      .snapshots()
      .map((q) => q.docs.map(Booking.fromSnapshot).toList());
});

/// One of the guardian's bookings by id; null while loading or if not theirs.
final bookingByIdProvider = Provider.family<Booking?, String>((ref, id) {
  for (final b in ref.watch(myBookingsProvider).value ?? const <Booking>[]) {
    if (b.id == id) return b;
  }
  return null;
});
