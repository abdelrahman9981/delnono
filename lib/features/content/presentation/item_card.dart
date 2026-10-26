import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/content/youtube.dart';
import '../../../core/format/arabic_digits.dart';
import '../data/content_repository.dart';
import '../domain/content_item.dart';

/// Where an item opens: a full-screen player for videos, a reading page for tips.
String contentPath(ContentItem item) => item.isVideo ? '/content/video/${item.id}' : '/content/tip/${item.id}';

/// "الرضاعة والهضم · فيديو · من ٦ لـ ١٢ شهر".
String contentMeta(BuildContext context, WidgetRef ref, ContentItem item) {
  final l10n = AppLocalizations.of(context);
  final categories = ref.watch(contentCategoriesProvider).value ?? defaultContentCategories;
  final category = categories.where((c) => c.id == item.category).firstOrNull?.name ?? item.category;
  return [
    category,
    item.isVideo ? l10n.contentVideo : l10n.contentTip,
    if (item.hasAgeRange) l10n.contentAgeRange(arabicDigits(item.ageFromMonths!), arabicDigits(item.ageToMonths!)),
  ].join(' · ');
}

/// A video's vertical thumbnail from YouTube, or a tip's icon.
class ContentThumb extends StatelessWidget {
  const ContentThumb({super.key, required this.item, this.width = 56});

  final ContentItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final icon = Container(
      color: item.isVideo ? c.pinkSoft : c.blueSoft,
      alignment: Alignment.center,
      child: Icon(
        item.isVideo ? Icons.play_circle_outline : Icons.article_outlined,
        color: item.isVideo ? c.pink : c.blue,
        size: width * 0.5,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: width * 16 / 9 * 0.75,
        child: !item.isVideo
            ? icon
            : Stack(fit: StackFit.expand, children: [
                Image.network(
                  youtubeThumb(item.youtubeId!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => icon,
                ),
                const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26)),
              ]),
      ),
    );
  }
}

class ContentCard extends ConsumerWidget {
  const ContentCard({super.key, required this.item, this.preview = false});

  final ContentItem item;

  /// The dashboard's preview: same look, does not navigate.
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    return Card(
      key: Key('content-item-${item.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: preview ? null : () => context.push(contentPath(item)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ContentThumb(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: text.titleSmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(contentMeta(context, ref, item), style: text.bodySmall?.copyWith(color: c.muted)),
              ]),
            ),
            // chevron_right mirrors in RTL: it points left (‹, forward).
            Icon(Icons.chevron_right, color: c.muted),
          ]),
        ),
      ),
    );
  }
}
