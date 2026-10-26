import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../data/content_repository.dart';
import 'item_card.dart';

/// A written tip: title and the doctor's text, read-only (works offline once loaded).
class TipScreen extends ConsumerWidget {
  const TipScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final content = ref.watch(publishedContentProvider);
    final item = content.value?.where((i) => i.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contentTip)),
      body: SafeArea(
        child: !content.hasValue
            ? const Center(child: CircularProgressIndicator())
            : item == null
            ? Center(child: Text(l10n.contentNotFound, key: const Key('content-not-found')))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Text(item.title, key: const Key('tip-title'), style: text.headlineSmall),
                  const SizedBox(height: 6),
                  Text(contentMeta(context, ref, item), style: text.bodySmall?.copyWith(color: c.muted)),
                  const SizedBox(height: 16),
                  Text(item.body ?? '', key: const Key('tip-body'), style: text.bodyLarge?.copyWith(height: 1.7)),
                  const SizedBox(height: 24),
                  Text(l10n.contentReviewed, style: text.bodySmall?.copyWith(color: c.muted)),
                ],
              ),
      ),
    );
  }
}
