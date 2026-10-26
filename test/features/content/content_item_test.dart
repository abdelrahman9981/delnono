import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/features/content/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ContentItem item(String id, {int order = 100, DateTime? at, int? from, int? to, String title = 'x'}) =>
      ContentItem(
        id: id,
        type: ContentType.tip,
        title: title,
        category: 'sleep',
        order: order,
        publishedAt: at,
        ageFromMonths: from,
        ageToMonths: to,
      );

  test('reads 005 items: a YouTube id means a video, missing order is 100', () {
    final v = ContentItem.fromMap('a', {'title': 't', 'category': 'fever', 'youtubeId': 'WjbDIjEH38U'});
    expect(v.type, ContentType.video);
    expect(v.isVideo, isTrue);
    expect(v.order, 100);
    final t = ContentItem.fromMap('b', {
      'type': 'tip',
      'title': 't',
      'category': 'sleep',
      'ageFromMonths': 6,
      'ageToMonths': 12,
      'publishedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    });
    expect(t.isVideo, isFalse);
    expect(t.coversAge(7), isTrue);
    expect(t.publishedAt, DateTime(2026, 10, 1));
  });

  test('age range: inside, edges, outside, and none', () {
    final a = item('a', from: 6, to: 12);
    expect([a.coversAge(5), a.coversAge(6), a.coversAge(12), a.coversAge(13)], [false, true, true, false]);
    expect(item('b').coversAge(7), isFalse);
  });

  test('search ignores hamza, taa marbuta, alef maqsura and tashkeel', () {
    final i = item('a', title: 'أسرع دوا ينزل الحرارة للأطفال');
    expect(i.matches('اسرع'), isTrue);
    expect(i.matches('الحراره'), isTrue);
    expect(i.matches('أطْفال'), isTrue);
    expect(i.matches(''), isTrue);
    expect(i.matches('النوم'), isFalse);
    expect(item('b', title: 'متى تتصلي').matches('متي'), isTrue);
  });

  test('order first, then newest; latest 3 by date', () {
    final list = [
      item('old', at: DateTime(2026, 1, 1)),
      item('new', at: DateTime(2026, 10, 1)),
      item('pinned', order: 1, at: DateTime(2025, 1, 1)),
      item('mid', at: DateTime(2026, 5, 1)),
    ]..sort(compareContent);
    expect(list.map((i) => i.id), ['pinned', 'new', 'mid', 'old']);
    expect(latestContent(list).map((i) => i.id), ['new', 'mid', 'old']);
  });
}
