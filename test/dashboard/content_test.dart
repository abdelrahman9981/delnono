import 'package:delnono/dashboard/screens/content_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

const _draft = {'id': 'd1', 'type': 'video', 'title': 'هل ينفع نحط ملح قبل عمر سنه', 'category': 'feeding', 'youtubeId': 'WjbDIjEH38U', 'url': 'https://youtube.com/shorts/WjbDIjEH38U', 'status': 'draft'};
const _published = {'id': 'p1', 'type': 'tip', 'title': '[نصيحة عن النوم]', 'category': 'sleep', 'body': '[نص]', 'status': 'published', 'order': 1};
const _archived = {'id': 'a1', 'type': 'tip', 'title': '[قديمة]', 'category': 'fever', 'body': '[نص]', 'status': 'archived'};

void main() {
  late FakeDashboardApi api;

  Future<void> open(WidgetTester tester, {bool doctor = false, List<Map<String, dynamic>> items = const [_draft, _published, _archived]}) async {
    api = FakeDashboardApi();
    await pumpDashboard(tester, const ContentScreen(), path: '/content', overrides: [
      ...dashboardOverrides(api: api, session: doctor ? doctorSession : secretarySession),
      contentItemsProvider.overrideWith((ref) => Stream.value(items)),
    ]);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('a secretary edits drafts only and has no publish, unpublish or archive', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('edit-d1')), findsOneWidget);
    expect(find.byKey(const Key('edit-p1')), findsNothing);
    for (final k in ['publish-d1', 'unpublish-p1', 'archive-d1', 'archive-p1', 'restore-a1', 'content-categories']) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
  });

  testWidgets('the doctor publishes, unpublishes, archives and restores through setContentStatus', (tester) async {
    await open(tester, doctor: true);
    await tap(tester, 'publish-d1');
    await tap(tester, 'unpublish-p1');
    await tap(tester, 'archive-d1');
    await tap(tester, 'restore-a1');
    expect(api.calls.map((c) => (c.$1, c.$2['id'], c.$2['status'])), [
      ('setContentStatus', 'd1', 'published'),
      ('setContentStatus', 'p1', 'draft'),
      ('setContentStatus', 'd1', 'archived'),
      ('setContentStatus', 'a1', 'draft'),
    ]);
  });

  testWidgets('the status filter shows one state', (tester) async {
    await open(tester);
    await tap(tester, 'segment-published');
    expect(find.byKey(const Key('content-p1')), findsOneWidget);
    expect(find.byKey(const Key('content-d1')), findsNothing);
  });

  testWidgets('a pasted YouTube link shows its id and thumbnail; another site is refused', (tester) async {
    await open(tester);
    await tap(tester, 'content-new');
    await tester.enterText(find.byKey(const Key('content-url')), 'https://vimeo.com/123');
    await tester.pump();
    expect(find.byKey(const Key('content-url-error')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('content-save'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('content-url')), 'https://youtube.com/shorts/ZHEaiIOfg2s?feature=share');
    await tester.pump();
    expect(find.byKey(const Key('content-thumb')), findsOneWidget);
    expect(find.text('رقم الفيديو: ZHEaiIOfg2s'), findsOneWidget);
  });

  testWidgets('a new video draft is saved with type, category, link, age range and order', (tester) async {
    await open(tester);
    await tap(tester, 'content-new');
    await tester.enterText(find.byKey(const Key('content-title')), 'فيديو جديد');
    await tester.tap(find.byKey(const Key('content-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('النوم').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('content-url')), 'https://youtu.be/ZHEaiIOfg2s');
    await tap(tester, 'content-age-toggle');
    await tester.enterText(find.byKey(const Key('content-age-from')), '6');
    await tester.enterText(find.byKey(const Key('content-age-to')), '12');
    await tester.enterText(find.byKey(const Key('content-order')), '5');
    await tester.pump();
    await tap(tester, 'content-save');
    final (name, data) = api.calls.single;
    expect(name, 'saveContent');
    expect(data, {
      'type': 'video',
      'title': 'فيديو جديد',
      'category': 'sleep',
      'url': 'https://youtu.be/ZHEaiIOfg2s',
      'body': '',
      'ageFromMonths': 6,
      'ageToMonths': 12,
      'order': 5,
    });
  });

  testWidgets('a tip needs text; the preview shows it as in the app', (tester) async {
    await open(tester);
    await tap(tester, 'content-new');
    await tap(tester, 'segment-ContentType.tip');
    await tester.enterText(find.byKey(const Key('content-title')), '[نصيحة جديدة]');
    await tester.tap(find.byKey(const Key('content-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الحرارة').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('content-save'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('content-body')), '[نص يكتبه الدكتور]');
    await tester.pump();
    await tap(tester, 'content-preview');
    expect(find.byKey(const Key('content-preview-dialog')), findsOneWidget);
    expect(find.byKey(const Key('preview-body')), findsOneWidget);
    expect(find.text('[نصيحة جديدة]'), findsWidgets);
  });

  testWidgets('import from the channel lists videos; adding one opens a draft with its link', (tester) async {
    await open(tester);
    api.responses['channelVideos'] = {
      'videos': [
        {'id': 'WjbDIjEH38U', 'title': '20 أكتوبر', 'published': '2026-10-20T10:00:00+00:00', 'alreadyAdded': true},
        {'id': 'ZHEaiIOfg2s', 'title': '19 أكتوبر', 'published': '2026-10-19T10:00:00+00:00', 'alreadyAdded': false},
      ],
    };
    await tap(tester, 'content-import');
    expect(find.byKey(const Key('import-WjbDIjEH38U')), findsNothing, reason: 'already added');
    await tap(tester, 'import-ZHEaiIOfg2s');
    expect(find.text('رقم الفيديو: ZHEaiIOfg2s'), findsOneWidget);
    // Staff type the title; the channel's date title is never copied (owner, 006).
    expect(tester.widget<TextField>(find.byKey(const Key('content-title'))).controller!.text, isEmpty);
    expect(tester.widget<FilledButton>(find.byKey(const Key('content-save'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('content-title')), 'عنوان تكتبه السكرتيرة');
    await tester.tap(find.byKey(const Key('content-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('النوم').last);
    await tester.pumpAndSettle();
    await tap(tester, 'content-save');
    expect(api.calls.last.$2['title'], 'عنوان تكتبه السكرتيرة');
  });

  testWidgets('the doctor saves the category list', (tester) async {
    await open(tester, doctor: true);
    await tap(tester, 'content-categories');
    await tester.enterText(find.byKey(const Key('category-fever')), 'الحرارة والسخونية');
    await tap(tester, 'categories-save');
    final (name, data) = api.calls.single;
    expect(name, 'saveContentCategories');
    expect((data['categories']! as List).first, {'id': 'fever', 'name': 'الحرارة والسخونية'});
  });

  for (final size in const [Size(1440, 900), Size(1024, 768), Size(800, 1000)]) {
    testWidgets('no overflow at ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      api = FakeDashboardApi();
      await pumpDashboard(tester, const ContentScreen(), path: '/content', size: size, overrides: [
        ...dashboardOverrides(api: api, session: doctorSession),
        contentItemsProvider.overrideWith((ref) => Stream.value(const [_draft, _published, _archived])),
      ]);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('content-new')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
