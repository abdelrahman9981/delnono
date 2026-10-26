import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { video, tip }

/// A published video or tip (006 data-model). Videos keep only the YouTube id (D-50).
class ContentItem {
  const ContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    this.body,
    this.youtubeId,
    this.ageFromMonths,
    this.ageToMonths,
    this.order = 100,
    this.publishedAt,
  });

  /// 005 items have no type or order: a link means a video.
  factory ContentItem.fromMap(String id, Map<String, dynamic> d) {
    final youtubeId = d['youtubeId'] as String?;
    final type = switch (d['type']) {
      'video' => ContentType.video,
      'tip' => ContentType.tip,
      _ => youtubeId != null ? ContentType.video : ContentType.tip,
    };
    return ContentItem(
      id: id,
      type: type,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? '',
      body: d['body'] as String?,
      youtubeId: youtubeId,
      ageFromMonths: (d['ageFromMonths'] as num?)?.toInt(),
      ageToMonths: (d['ageToMonths'] as num?)?.toInt(),
      order: (d['order'] as num?)?.toInt() ?? 100,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final ContentType type;
  final String title;
  final String category;
  final String? body;
  final String? youtubeId;
  final int? ageFromMonths;
  final int? ageToMonths;
  final int order;
  final DateTime? publishedAt;

  bool get isVideo => type == ContentType.video && youtubeId != null;
  bool get hasAgeRange => ageFromMonths != null && ageToMonths != null;

  /// Items without an age range are for every age but never in the age section (spec Q4).
  bool coversAge(int months) => hasAgeRange && ageFromMonths! <= months && months <= ageToMonths!;

  bool matches(String query) {
    final q = normalizeArabic(query);
    return q.isEmpty || normalizeArabic(title).contains(q);
  }
}

class ContentCategory {
  const ContentCategory(this.id, this.name);

  final String id;
  final String name;
}

/// BRD categories, until the doctor saves her list (006 R5).
const defaultContentCategories = [
  ContentCategory('fever', 'الحرارة'),
  ContentCategory('feeding', 'الرضاعة والهضم'),
  ContentCategory('sleep', 'النوم'),
  ContentCategory('allergy', 'الحساسية'),
];

/// Children older than this get no age-based section (requirements item 3).
const ageContentLimitMonths = 48;

final _marks = RegExp('[ً-ٰٟـ]');

/// Search form of Arabic text (006 R9): no tashkeel or tatweel; alef, taa marbuta, yaa unified.
String normalizeArabic(String s) => s
    .replaceAll(_marks, '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

/// Lower order first, then newest published first (spec clarification).
int compareContent(ContentItem a, ContentItem b) {
  final byOrder = a.order.compareTo(b.order);
  if (byOrder != 0) return byOrder;
  final at = a.publishedAt ?? DateTime(2000);
  final bt = b.publishedAt ?? DateTime(2000);
  return bt.compareTo(at);
}

/// Up to [count] latest published items, for Home.
List<ContentItem> latestContent(List<ContentItem> items, {int count = 3}) {
  final list = [...items]
    ..sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
  return list.take(count).toList();
}
