import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  Future<void> enterAndSend(WidgetTester tester, String number) async {
    await tester.enterText(find.byKey(const Key('phone-field')), number);
    await tester.tap(find.text('ابعتيلي الكود'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the design text in Arabic', (tester) async {
    await SignInHarness().pump(tester);
    expect(find.text('رقم موبايلك إيه؟'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('لو العيادة سجلت أطفالك قبل كده، استخدمي نفس الرقم.'), findsOneWidget);
  });

  testWidgets('an invalid number is blocked before any SMS is sent', (tester) async {
    final h = SignInHarness();
    await h.pump(tester);
    for (final bad in ['0123', '0221234567', '010123456789']) {
      await enterAndSend(tester, bad);
      expect(find.text('اكتبي رقم موبايل مصري صحيح، زي 010 1234 5678.'), findsOneWidget, reason: bad);
    }
    expect(h.service.sent, isEmpty);
    expect(h.location, startsWith('/sign-in?'));
  });

  testWidgets('a valid number sends one code and opens the code screen, keeping from', (tester) async {
    final h = SignInHarness();
    await h.pump(tester);
    await enterAndSend(tester, '010 1234 5678');
    expect(h.service.sent.single.phone, '+201012345678');
    expect(h.location, '/sign-in/code?from=%2Fbooking');
    expect(find.text('اكتبي الكود'), findsOneWidget);
  });

  testWidgets('Arabic-Indic digits are accepted', (tester) async {
    final h = SignInHarness();
    await h.pump(tester);
    await enterAndSend(tester, '٠١٠١٢٣٤٥٦٧٨');
    expect(h.service.sent.single.phone, '+201012345678');
  });

  testWidgets('a Firebase error is shown in Arabic and stays on the screen', (tester) async {
    final h = SignInHarness();
    h.service.sendError = FirebaseAuthException(code: 'too-many-requests');
    await h.pump(tester);
    await enterAndSend(tester, '01012345678');
    expect(find.text('محاولات كتير. استني شوية وجربي تاني.'), findsOneWidget);
    expect(h.location, startsWith('/sign-in?'));
  });
}
