import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/settings/settings_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// Every content item with its status; staff read drafts (rules).
final contentItemsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('content')
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs) {'id': d.id, ...d.data()},
        ]..sort((a, b) => '${a['title']}'.compareTo('${b['title']}')),
      ),
);

const contentCategories = ['fever', 'feeding', 'sleep', 'allergy'];

String categoryLabel(AppLocalizations l10n, String c) => switch (c) {
  'fever' => l10n.dashCatFever,
  'feeding' => l10n.dashCatFeeding,
  'sleep' => l10n.dashCatSleep,
  _ => l10n.dashCatAllergy,
};

String statusLabel(AppLocalizations l10n, String s) => switch (s) {
  'published' => l10n.dashPublished,
  'archived' => l10n.dashArchived,
  _ => l10n.dashDraft,
};

/// Tips and videos (005 US6, FR-039, D-19): staff draft; only the doctor publishes or archives.
class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(contentItemsProvider).value ?? const <Map<String, dynamic>>[];
    final isDoctor = ref.watch(staffSessionProvider).value?.isDoctor ?? false;
    return DashPage(
      title: l10n.dashNavContent,
      actions: [
        FilledButton.icon(
          key: const Key('content-new'),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const ContentDialog()),
          icon: const Icon(Icons.add),
          label: Text(l10n.dashNewItem),
        ),
      ],
      showClinic: false,
      children: [
        DashCard(
          title: l10n.dashContentList,
          hint: l10n.dashDraftNote,
          icon: Icons.menu_book_outlined,
          tone: Tone.pink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty) Text(l10n.dashNothingYet),
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ActionRow(
                  key: Key('content-${item['id']}'),
                  title: '${item['title']}',
                  subtitle: categoryLabel(l10n, '${item['category']}'),
                  actions: [
                    StatusPill(statusLabel(l10n, '${item['status']}'), switch (item['status']) {
                      'published' => PillKind.ok,
                      'archived' => PillKind.noShow,
                      _ => PillKind.warn,
                    }),
                    if (item['status'] == 'draft' || isDoctor)
                      IconButton(
                        tooltip: l10n.dashEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => ContentDialog(item: item),
                        ),
                      ),
                    if (isDoctor && item['status'] != 'published')
                      FilledButton.tonal(
                        key: Key('publish-${item['id']}'),
                        onPressed: () => runAction(
                          context,
                          () => ref.read(dashboardApiProvider).call('saveContent', {...item, 'status': 'published'}),
                          done: l10n.dashPublished,
                        ),
                        child: Text(l10n.dashPublish),
                      ),
                    if (isDoctor && item['status'] == 'published')
                      OutlinedButton(
                        key: Key('archive-${item['id']}'),
                        onPressed: () => runAction(
                          context,
                          () => ref.read(dashboardApiProvider).call('saveContent', {...item, 'status': 'archived'}),
                          done: l10n.dashArchived,
                        ),
                        child: Text(l10n.dashArchive),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ContentDialog extends ConsumerStatefulWidget {
  const ContentDialog({super.key, this.item});

  final Map<String, dynamic>? item;

  @override
  ConsumerState<ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends ConsumerState<ContentDialog> {
  late final _title = TextEditingController(text: '${widget.item?['title'] ?? ''}');
  late final _url = TextEditingController(text: '${widget.item?['url'] ?? ''}');
  late final _body = TextEditingController(text: '${widget.item?['body'] ?? ''}');
  late final _from = TextEditingController(text: '${widget.item?['ageFromMonths'] ?? 0}');
  late final _to = TextEditingController(text: '${widget.item?['ageToMonths'] ?? 48}');
  late String _category = '${widget.item?['category'] ?? 'fever'}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.item == null ? l10n.dashNewItem : l10n.dashEdit),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('content-title'),
              controller: _title,
              decoration: InputDecoration(labelText: l10n.dashItemTitle),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('content-category'),
              initialValue: _category,
              items: [
                for (final c in contentCategories) DropdownMenuItem(value: c, child: Text(categoryLabel(l10n, c))),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
              decoration: InputDecoration(labelText: l10n.dashCategory),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.dashAgeFrom),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _to,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.dashAgeTo),
                  ),
                ),
              ],
            ),
            TextField(
              key: const Key('content-url'),
              controller: _url,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.dashLink),
            ),
            TextField(
              controller: _body,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.dashBody),
            ),
            const SizedBox(height: 8),
            Text(l10n.dashDraftNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('content-save'),
          onPressed: () async {
            final ok = await runAction(
              context,
              () => ref.read(dashboardApiProvider).call('saveContent', {
                if (widget.item != null) 'id': widget.item!['id'],
                'title': _title.text.trim(),
                'category': _category,
                'url': _url.text.trim(),
                'body': _body.text.trim(),
                'ageFromMonths': int.tryParse(_from.text) ?? 0,
                'ageToMonths': int.tryParse(_to.text) ?? 48,
                'status': widget.item?['status'] == 'published' ? 'published' : 'draft',
              }),
              done: l10n.dashSaved,
            );
            if (ok && context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
