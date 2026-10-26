import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../domain/content_item.dart';

/// Published items for everyone, signed in or not (rules). Firestore's cache keeps them offline.
final publishedContentProvider = StreamProvider<List<ContentItem>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('content')
      .where('status', isEqualTo: 'published')
      .snapshots()
      .map((q) => [for (final d in q.docs) ContentItem.fromMap(d.id, d.data())]..sort(compareContent)),
);

/// The doctor's category list (`settings/content`), BRD categories until she saves one.
final contentCategoriesProvider = StreamProvider<List<ContentCategory>>(
  (ref) => ref.watch(firestoreProvider).doc('settings/content').snapshots().map((s) {
    final list = s.data()?['categories'] as List<dynamic>?;
    if (list == null || list.isEmpty) return defaultContentCategories;
    return [
      for (final c in list.cast<Map<String, dynamic>>()) ContentCategory('${c['id']}', '${c['name']}'),
    ];
  }),
);
