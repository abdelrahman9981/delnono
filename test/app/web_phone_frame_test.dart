import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/theme.dart';
import 'package:delnono/app/web_phone_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      builder: (context, child) => WebPhoneFrame(force: true, child: child!),
      home: const Scaffold(body: SizedBox.expand(key: Key('app'))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('desktop: the app in a 390 × 844 phone frame with its name above (D-43)', (tester) async {
    await pump(tester, const Size(1440, 1000));
    expect(find.byKey(const Key('web-phone-frame')), findsOneWidget);
    expect(find.text('دكتور النونو'), findsOneWidget);
    final app = tester.getSize(find.byKey(const Key('app')));
    final scale = app.width / 390;
    expect(app.height / scale, closeTo(844, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short desktop window scales the frame down instead of overflowing', (tester) async {
    await pump(tester, const Size(1280, 700));
    expect(find.byKey(const Key('web-phone-frame')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone width: full screen, no frame', (tester) async {
    await pump(tester, const Size(390, 844));
    expect(find.byKey(const Key('web-phone-frame')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('app'))), const Size(390, 844));
  });
}
