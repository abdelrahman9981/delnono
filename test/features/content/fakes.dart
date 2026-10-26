import 'package:delnono/features/content/application/connectivity.dart';
import 'package:delnono/features/content/data/content_repository.dart';
import 'package:delnono/features/content/domain/content_item.dart';
import 'package:delnono/features/content/presentation/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Published items as the seed has them (006): videos with age ranges and a bracketed tip.
final sampleContent = [
  ContentItem(
    id: 'salt',
    type: ContentType.video,
    title: 'هل ينفع نحط ملح قبل عمر سنه',
    category: 'feeding',
    youtubeId: 'WjbDIjEH38U',
    ageFromMonths: 4,
    ageToMonths: 12,
    publishedAt: DateTime(2026, 10, 20),
  ),
  ContentItem(
    id: 'vitd',
    type: ContentType.video,
    title: 'فيتامين د بيعمل ارهاق للاطفال ومش بيناموا بسببه',
    category: 'sleep',
    youtubeId: 'KDOV-4nbWqU',
    ageFromMonths: 0,
    ageToMonths: 24,
    publishedAt: DateTime(2026, 10, 15),
  ),
  ContentItem(
    id: 'tip-fever',
    type: ContentType.tip,
    title: '[نصيحة عن الحرارة · يكتبها الدكتور]',
    category: 'fever',
    body: '[نص النصيحة · يكتبه الدكتور قبل النشر]',
    publishedAt: DateTime(2026, 10, 1),
  ),
  ContentItem(
    id: 'newborn',
    type: ContentType.video,
    title: 'تلت حجات في حديثي الولادة',
    category: 'feeding',
    youtubeId: 'eH9QRdN_Hgw',
    ageFromMonths: 0,
    ageToMonths: 1,
    publishedAt: DateTime(2026, 9, 1),
  ),
];

/// A player stand-in: tapping it reports the YouTube error (not embeddable).
Widget fakePlayer(String id, VoidCallback onError) =>
    GestureDetector(key: Key('player-$id'), onTap: onError, child: const ColoredBox(color: Colors.grey));

/// Content providers for widget tests: [items] published, BRD categories, [online].
List<Override> contentOverrides({List<ContentItem>? items, bool online = true, List<String>? opened}) => [
  publishedContentProvider.overrideWith((ref) => Stream.value(items ?? const <ContentItem>[])),
  contentCategoriesProvider.overrideWith((ref) => Stream.value(defaultContentCategories)),
  onlineProvider.overrideWith((ref) => Stream.value(online)),
  videoPlayerBuilderProvider.overrideWithValue(fakePlayer),
  openYoutubeProvider.overrideWithValue((id) async {
    opened?.add(id);
    return true;
  }),
];
