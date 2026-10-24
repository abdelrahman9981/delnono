import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_repository.dart';
import '../../features/booking/domain/booking.dart';

/// A booking as staff see it: the 002 booking plus the queue fields (005 data-model.md).
class QueueBooking {
  const QueueBooking({required this.booking, this.statusRaw = 'confirmed', this.arrivedAt, this.payment});

  factory QueueBooking.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) => QueueBooking(
    booking: Booking.fromSnapshot(s),
    statusRaw: s.data()?['status'] as String? ?? 'confirmed',
    arrivedAt: (s.data()?['arrivedAt'] as Timestamp?)?.toDate(),
    payment: s.data()?['payment'] as Map<String, dynamic>?,
  );

  final Booking booking;
  final String statusRaw;
  final DateTime? arrivedAt;
  final Map<String, dynamic>? payment;
}

class WalkIn {
  const WalkIn({
    required this.id,
    required this.hour,
    required this.familyName,
    required this.phone,
    required this.children,
    required this.status,
    this.arrivedAt,
    this.payment,
  });

  factory WalkIn.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return WalkIn(
      id: s.id,
      hour: (d['hour'] as num).toInt(),
      familyName: d['familyName'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      children: [for (final c in (d['children'] as List? ?? const [])) '${(c as Map)['name']}'],
      status: d['status'] as String? ?? 'arrived',
      arrivedAt: (d['arrivedAt'] as Timestamp?)?.toDate(),
      payment: d['payment'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final int hour;
  final String familyName;
  final String phone;
  final List<String> children;
  final String status;
  final DateTime? arrivedAt;
  final Map<String, dynamic>? payment;
}

typedef ClinicDay = ({String clinicId, String date});

/// The clinic's bookings on a date, not cancelled.
final dayBookingsProvider = StreamProvider.family<List<QueueBooking>, ClinicDay>(
  (ref, key) => ref
      .watch(firestoreProvider)
      .collection('bookings')
      .where('clinicId', isEqualTo: key.clinicId)
      .where('date', isEqualTo: key.date)
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs)
            if (d.data()['status'] != 'cancelled') QueueBooking.fromSnapshot(d),
        ]..sort((a, b) => a.booking.hour.compareTo(b.booking.hour)),
      ),
);

final dayWalkInsProvider = StreamProvider.family<List<WalkIn>, ClinicDay>(
  (ref, key) => ref
      .watch(firestoreProvider)
      .collection('walkIns')
      .where('clinicId', isEqualTo: key.clinicId)
      .where('date', isEqualTo: key.date)
      .snapshots()
      .map((q) => q.docs.map(WalkIn.fromSnapshot).toList()),
);

/// Whether walk-ins are stopped for the day (D-07).
final walkInsStoppedProvider = StreamProvider.family<bool, ClinicDay>(
  (ref, key) => ref
      .watch(firestoreProvider)
      .doc('days/${key.clinicId}_${key.date}')
      .snapshots()
      .map((s) => s.data()?['walkInsStopped'] == true),
);
