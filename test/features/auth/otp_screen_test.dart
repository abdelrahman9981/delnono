import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  /// Code already sent to +201012345678 with default settings (5 min, 5 attempts, 60 s).
  Future<SignInHarness> onCodeScreen(WidgetTester tester) async {
    final h = SignInHarness();
    await tester.runAsync(() => h.otp.sendCode('+201012345678'));
    await h.pump(tester, at: '/sign-in/code?from=%2Fbooking');
    return h;
  }

  Future<void> typeCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('otp-field')), code);
    await tester.pumpAndSettle();
  }

  FilledButton confirm(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تأكيد'));

  testWidgets('shows the number and how long the code is valid', (tester) async {
    await onCodeScreen(tester);
    expect(find.textContaining('+20 10 1234 5678'), findsOneWidget);
    expect(find.text('الكود صالح ٥ دقايق'), findsOneWidget);
  });

  testWidgets('resend is disabled with a countdown, then enabled (FR-008)', (tester) async {
    final h = await onCodeScreen(tester);
    expect(find.text('إعادة الإرسال بعد ١:٠٠'), findsOneWidget);
    expect(find.text('ابعتي الكود تاني'), findsNothing);

    await h.wait(tester, const Duration(seconds: 18));
    expect(find.text('إعادة الإرسال بعد ٠:٤٢'), findsOneWidget);

    await h.wait(tester, const Duration(seconds: 42));
    expect(find.text('ابعتي الكود تاني'), findsOneWidget);
    await tester.tap(find.text('ابعتي الكود تاني'));
    await tester.pumpAndSettle();
    expect(h.service.sent, hasLength(2));
    expect(find.text('إعادة الإرسال بعد ١:٠٠'), findsOneWidget);
  });

  testWidgets('wrong codes show attempts left in Arabic, then lock the code (FR-007)', (tester) async {
    final h = await onCodeScreen(tester);

    await typeCode(tester, '000000');
    expect(find.text('الكود مش صح. فاضلك ٤ محاولات، وبعدها اطلبي كود جديد.'), findsOneWidget);

    await typeCode(tester, '000000');
    expect(find.text('الكود مش صح. فاضلك ٣ محاولات، وبعدها اطلبي كود جديد.'), findsOneWidget);

    await typeCode(tester, '000000');
    expect(find.text('الكود مش صح. فاضلك محاولتين، وبعدها اطلبي كود جديد.'), findsOneWidget);

    await typeCode(tester, '000000');
    expect(find.text('الكود مش صح. فاضلك محاولة واحدة، وبعدها اطلبي كود جديد.'), findsOneWidget);

    await typeCode(tester, '000000');
    expect(find.text('الكود مش صح، والمحاولات خلصت. اطلبي كود جديد.'), findsOneWidget);
    expect(h.container.read(otpControllerProvider).hasCode, isFalse);
    expect(tester.widget<TextField>(find.byKey(const Key('otp-field'))).enabled, isFalse);
    expect(h.service.tried, hasLength(5));
  });

  testWidgets('an expired code cannot be used (FR-006)', (tester) async {
    final h = await onCodeScreen(tester);
    await h.wait(tester, const Duration(minutes: 5));
    expect(find.text('الكود خلص وقته. اطلبي كود جديد.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('otp-field'))).enabled, isFalse);
    expect(confirm(tester).onPressed, isNull);
    expect(find.text('ابعتي الكود تاني'), findsOneWidget);
  });

  testWidgets('the right code signs in', (tester) async {
    final h = await onCodeScreen(tester);
    await typeCode(tester, '123456');
    expect(h.container.read(otpControllerProvider).phase, OtpPhase.signedIn);
  });

  testWidgets('change number goes back to sign-in, keeping from', (tester) async {
    final h = await onCodeScreen(tester);
    await tester.tap(find.text('غيّري الرقم'));
    await tester.pumpAndSettle();
    expect(h.location, '/sign-in?from=%2Fbooking');
  });
}
