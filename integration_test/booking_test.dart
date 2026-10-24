// Booking a visit end to end (002 quickstart scenarios 1–2; FR-001 to FR-013), at the seeded second
// clinic (004 quickstart scenario 3).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

final pickerOverride =
    birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2023, 3, 3));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('book a visit for two siblings at clinic 2: one place, its visit price, success screen', (tester) async {
    await startApp(tester, overrides: [pickerOverride]);
    await registerWithChild(tester, '+201000000087', 'نهى سعيد', 'كريم');
    await addChild(tester, 'ليلى');

    await tester.tap(find.text('حجز'));
    // Two clinics: the clinic comes first (004 FR-006).
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-2'))));
    await tapInList(tester, find.byKey(const Key('clinic-clinic-2')));
    await settle(tester, () => shows(keysStarting('day-')));
    await tapInList(tester, keysStarting('day-').first);
    await settle(tester, () => shows(keysStarting('hour-')));
    final hourKey = (tester.widget(keysStarting('hour-').first).key! as ValueKey<String>).value;
    await tapInList(tester, keysStarting('hour-').first);
    await tapInList(tester, keysStarting('child-').first);
    await tapInList(tester, keysStarting('child-').last);
    await settle(tester, () => shows(find.byKey(const Key('summary-total'))));
    expect(tester.widget<Text>(find.byKey(const Key('summary-total'))).data, '٣٥٠ جنيه', reason: "clinic 2's visit price");

    await tapInList(tester, find.byKey(const Key('confirm-booking')));
    await settle(tester, () => shows(find.byKey(const Key('booking-number'))));
    expect(location(tester), startsWith('/booking/done/'));
    expect(find.text('تم الحجز بنجاح'), findsOneWidget);
    expect(find.textContaining('كريم'), findsWidgets);
    expect(find.textContaining('مدينة نصر'), findsWidgets, reason: 'the clinic name and address');

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bookings = await FirebaseFirestore.instance.collection('bookings').where('guardianUid', isEqualTo: uid).get();
    final b = bookings.docs.single;
    expect((b.get('children') as List).length, 2);
    expect(b.get('price')['total'], 350);
    expect(b.get('clinicId'), 'clinic-2');
    final slot = await FirebaseFirestore.instance
        .collection('slots')
        .where('clinicId', isEqualTo: 'clinic-2')
        .where('date', isEqualTo: b.get('date'))
        .where('hour', isEqualTo: int.parse(hourKey.substring(5)))
        .get();
    expect(slot.docs.single.get('taken'), 1, reason: 'siblings take one place');
  });
}
