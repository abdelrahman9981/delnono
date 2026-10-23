import 'package:delnono/features/booking/data/bookings_repository.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/booking/presentation/booking_success_screen.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';

final booking = Booking(
  id: 'b1',
  number: 248,
  visitType: VisitType.visit,
  children: const [BookedChild(childId: 'a', name: 'يوسف', vaccines: [])],
  date: '2026-11-15',
  hour: 18,
  startsAt: DateTime.utc(2026, 11, 15, 16),
  status: BookingStatus.confirmed,
  price: const PriceSnapshot(visitAmount: 300, visitCovered: false, vaccines: [], total: 300, hasHiddenPrices: false),
);

void main() {
  Future<ScreenHarness> open(WidgetTester tester) async {
    final h = ScreenHarness(
      initial: '/booking/done/b1',
      routes: [GoRoute(path: '/booking/done/:id', builder: (_, s) => BookingSuccessScreen(bookingId: s.pathParameters['id']!))],
      overrides: [
        myBookingsProvider.overrideWith((ref) => Stream.value([booking])),
        guardianProvider.overrideWith((ref) => Stream.value(const Guardian(
              uid: 'u1', phone: '+201000000099', fullName: 'سارة محمود', relation: Relation.mother, consentVersion: 1))),
      ],
    );
    await h.pump(tester);
    return h;
  }

  testWidgets('shows the booking as in the design', (tester) async {
    await open(tester);
    expect(find.text('تم الحجز بنجاح'), findsOneWidget);
    expect(find.text('ميعادكم اتأكد يا سارة'), findsOneWidget);
    expect(find.text('مستنيين يوسف في العيادة'), findsOneWidget);
    expect(find.text('# نونو ٢٤٨'), findsOneWidget);
    expect(find.text('مؤكد'), findsOneWidget);
    expect(find.text('الأحد، ١٥ نوفمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('٦ لـ ٧ م'), findsOneWidget);
    expect(find.text('كشف يوسف'), findsOneWidget);
    expect(find.text('٣٠٠ جنيه'), findsOneWidget);
    expect(find.text('الدخول بالأسبقية جوه الساعة المحجوزة'), findsOneWidget);
  });

  testWidgets('both buttons navigate', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('view-my-bookings')));
    expect(h.location, '/booking/mine');
  });
}
