import 'package:cloud_firestore/cloud_firestore.dart';

import 'price_preview.dart';

enum BookingStatus { confirmed, arrived, done, cancelled, noShow }

class BookedChild {
  const BookedChild({required this.childId, required this.name, required this.vaccines});

  final String childId;
  final String name;
  final List<String> vaccines;
}

/// `bookings/{id}` (data-model.md). Written only by Cloud Functions.
class Booking {
  const Booking({
    required this.id,
    required this.number,
    required this.visitType,
    required this.children,
    required this.date,
    required this.hour,
    required this.startsAt,
    required this.status,
    required this.price,
  });

  factory Booking.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return Booking(
      id: snap.id,
      number: (d['number'] as num).toInt(),
      visitType: d['visitType'] == 'vaccine_only' ? VisitType.vaccineOnly : VisitType.visit,
      children: [
        for (final c in (d['children'] as List).cast<Map>())
          BookedChild(
            childId: c['childId'] as String,
            name: c['name'] as String,
            vaccines: (c['vaccines'] as List? ?? const []).cast<String>(),
          ),
      ],
      date: d['date'] as String,
      hour: (d['hour'] as num).toInt(),
      startsAt: (d['startsAt'] as Timestamp).toDate(),
      status: switch (d['status']) {
        'arrived' => BookingStatus.arrived,
        'done' => BookingStatus.done,
        'cancelled' => BookingStatus.cancelled,
        'no_show' => BookingStatus.noShow,
        _ => BookingStatus.confirmed,
      },
      price: PriceSnapshot.fromMap(Map<String, dynamic>.from(d['price'] as Map)),
    );
  }

  final String id;
  final int number;
  final VisitType visitType;
  final List<BookedChild> children;
  final String date;
  final int hour;
  final DateTime startsAt;
  final BookingStatus status;
  final PriceSnapshot price;

  bool get isActive => status == BookingStatus.confirmed || status == BookingStatus.arrived;
}
