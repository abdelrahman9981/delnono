import 'package:delnono/features/child_profile/presentation/vaccines_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

void main() {
  Future<void> open(WidgetTester tester, String childId) async {
    final h = ScreenHarness(
      initial: '/children/$childId/vaccines',
      routes: [GoRoute(path: '/children/:id/vaccines', builder: (_, s) => VaccinesScreen(childId: s.pathParameters['id']!))],
      overrides: profileOverrides(),
    );
    await h.pump(tester);
  }

  Finder inRow(String key, Finder f) => find.descendant(of: find.byKey(Key(key)), matching: f);

  testWidgets('schedule source and last review date (FR-011)', (tester) async {
    await open(tester, 'c2');
    expect(inRow('schedule-source', find.textContaining('المصدر: [جدول وزارة الصحة · مؤقت]')), findsOneWidget);
    expect(inRow('schedule-source', find.textContaining('آخر مراجعة: ١ أكتوبر ٢٠٢٦')), findsOneWidget);
  });

  testWidgets('each basic dose shows its state for a 9-month-old on 24 Oct 2026 (FR-007, FR-008)', (tester) async {
    await open(tester, 'c2');
    // Born 20 Jan 2026: birth dose given with a lot; 6 months given without a lot; 9 months due
    // since 20 Oct; 12 and 18 months scheduled.
    expect(inRow('dose-s01', find.text('اتاخدت')), findsOneWidget);
    expect(inRow('dose-s01', find.text('رقم التشغيلة: LOT-1101')), findsOneWidget);
    expect(inRow('dose-s05', find.text('اتاخدت')), findsOneWidget);
    expect(inRow('dose-s05', find.textContaining('رقم التشغيلة')), findsNothing);
    expect(inRow('dose-s06', find.text('مستحقة')), findsOneWidget);
    expect(inRow('dose-s06', find.text('ميعادها ٢٠ أكتوبر ٢٠٢٦')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('dose-s08')));
    expect(inRow('dose-s07', find.text('مجدولة')), findsOneWidget);
    expect(inRow('dose-s08', find.text('مجدولة')), findsOneWidget);
  });

  testWidgets('late and missed for an older child', (tester) async {
    await open(tester, 'c1');
    // Born 15 Mar 2024: 6, 9, 12 months not given → late; 18 months has a last age of 24 months → missed.
    expect(inRow('dose-s06', find.text('متأخرة')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('dose-s08')));
    expect(inRow('dose-s08', find.text('فائتة')), findsOneWidget);
  });

  testWidgets('additional vaccines are marked, with the doctor\'s details and price only when shown (FR-010)', (tester) async {
    await open(tester, 'c1');
    await scrollTo(tester, find.byKey(const Key('additional-v3')));
    expect(find.text('تطعيمات إضافية'), findsOneWidget);
    expect(inRow('additional-v3', find.text('إضافي')), findsOneWidget);
    expect(inRow('additional-v3', find.text('العمر المناسب: سنة')), findsOneWidget);
    expect(inRow('additional-v3', find.text('عدد الجرعات: ٢')), findsOneWidget);
    expect(inRow('additional-v3', find.text('الفاصل بين الجرعات: ٤ أسابيع')), findsOneWidget);
    expect(inRow('additional-v3', find.text('[ملاحظة الدكتور · مؤقتة]')), findsOneWidget);
    expect(inRow('additional-v3', find.textContaining('السعر')), findsNothing, reason: 'price hidden by the doctor');
    expect(inRow('additional-v3', find.textContaining('LOT-3001')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('additional-v5')));
    expect(inRow('additional-v5', find.text('السعر: ٣٠٠ جنيه')), findsOneWidget);
    expect(inRow('additional-v5', find.text('متأخرة')), findsNothing, reason: 'optional: no late or missed state');
  });

  testWidgets('placeholder vaccine names appear in brackets (FR-012)', (tester) async {
    await open(tester, 'c2');
    expect(find.textContaining('[تطعيم مؤقت ١]'), findsWidgets);
  });
}
