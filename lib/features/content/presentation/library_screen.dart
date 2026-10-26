import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/widgets/load_error.dart';
import '../../auth/data/auth_repository.dart';
import '../../booking/domain/clinic_time.dart';
import '../../child_profile/application/selected_child.dart';
import '../../child_profile/domain/child_age.dart';
import '../data/content_repository.dart';
import '../domain/content_item.dart';
import 'item_card.dart';

/// «محتوى» (requirements item 9, docs/design/screens/Content.dc.html): published videos and tips
/// for everyone, by category and title search; «مناسب لسن …» for a signed-in guardian's child
/// under 4 years.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final content = ref.watch(publishedContentProvider);
    final categories = ref.watch(contentCategoriesProvider).value ?? defaultContentCategories;
    final items = content.value ?? const <ContentItem>[];
    final shown = [
      for (final i in items)
        if ((_category == null || i.category == _category) && i.matches(_search.text)) i,
    ];

    final signedIn = ref.watch(authStateProvider).value != null;
    final child = signedIn ? ref.watch(currentChildProvider) : null;
    final months = child == null
        ? null
        : ageInMonths(child.birthDate, ClinicTime.dateOf(ref.watch(clockProvider)()));
    final forAge = months == null || months >= ageContentLimitMonths
        ? const <ContentItem>[]
        : [for (final i in items) if (i.coversAge(months)) i];

    Widget chip(String key, String label, String? id) => ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: _category == id,
      onSelected: (_) => setState(() => _category = id),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(l10n.appTitle, style: text.labelLarge?.copyWith(color: c.blue)),
            Text(l10n.contentTitle, style: text.headlineMedium),
            const SizedBox(height: 12),
            TextField(
              key: const Key('content-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.contentSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              chip('chip-all', l10n.contentAll, null),
              for (final cat in categories) chip('chip-${cat.id}', cat.name, cat.id),
            ]),
            if (content.hasError && !content.hasValue)
              LoadErrorView(onRetry: () => ref.invalidate(publishedContentProvider))
            else if (!content.hasValue)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else ...[
              if (forAge.isNotEmpty && child != null) ...[
                const SizedBox(height: 16),
                Text(l10n.contentForAge(child.name), key: const Key('content-for-age'), style: text.titleMedium),
                const SizedBox(height: 8),
                for (final i in forAge) ...[ContentCard(key: Key('age-${i.id}'), item: i), const SizedBox(height: 8)],
              ],
              const SizedBox(height: 16),
              Text(l10n.contentAllItems, style: text.titleMedium),
              const SizedBox(height: 8),
              if (items.isEmpty)
                _Note(key: const Key('content-empty'), text: l10n.contentEmpty)
              else if (shown.isEmpty)
                _Note(key: const Key('content-no-results'), text: l10n.contentNoResults),
              for (final i in shown) ...[ContentCard(item: i), const SizedBox(height: 8)],
            ],
            const SizedBox(height: 12),
            Text(l10n.contentReviewed, textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
  );
}
