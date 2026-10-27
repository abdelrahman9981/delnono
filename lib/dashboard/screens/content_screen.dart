import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/settings/settings_repository.dart';
import '../../features/content/data/content_repository.dart';
import '../../features/content/domain/content_item.dart';
import '../../features/content/presentation/item_card.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';
import 'content_dialog.dart';

/// Every content item with its status; staff read drafts (rules).
final contentItemsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('content')
      .snapshots()
      .map(
        (q) => [
          for (final d in q.docs) {'id': d.id, ...d.data()},
        ]..sort((a, b) {
          final byOrder = ((a['order'] as num?) ?? 100).compareTo((b['order'] as num?) ?? 100);
          return byOrder != 0 ? byOrder : '${a['title']}'.compareTo('${b['title']}');
        }),
      ),
);

String statusLabel(AppLocalizations l10n, String s) => switch (s) {
  'published' => l10n.dashPublished,
  'archived' => l10n.dashArchived,
  _ => l10n.dashDraft,
};

/// «المحتوى والقوائم» (006 US4, D-19): staff draft videos and tips; only the doctor publishes,
/// unpublishes, archives and restores (each audited) and edits the categories.
class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(contentItemsProvider).value ?? const <Map<String, dynamic>>[];
    final items = [for (final i in all) if (_filter == 'all' || (i['status'] ?? 'draft') == _filter) i];
    final categories = ref.watch(contentCategoriesProvider).value ?? defaultContentCategories;
    final isDoctor = ref.watch(staffSessionProvider).value?.isDoctor ?? false;
    String categoryName(String id) => categories.where((x) => x.id == id).firstOrNull?.name ?? id;

    Widget statusAction(Map<String, dynamic> item, String status, String key, String label, String done, {bool filled = false}) {
      void run() => runAction(
        context,
        () => ref.read(dashboardApiProvider).call('setContentStatus', {'id': item['id'], 'status': status}),
        done: done,
      );
      return filled
          ? FilledButton.tonal(key: Key('$key-${item['id']}'), onPressed: run, child: Text(label))
          : OutlinedButton(key: Key('$key-${item['id']}'), onPressed: run, child: Text(label));
    }

    return DashPage(
      title: l10n.dashNavContent,
      actions: [
        OutlinedButton.icon(
          key: const Key('content-import'),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const ChannelImportDialog()),
          icon: const Icon(Icons.smart_display_outlined),
          label: Text(l10n.dashContentImport),
        ),
        if (isDoctor)
          OutlinedButton.icon(
            key: const Key('content-categories'),
            onPressed: () => showDialog<void>(context: context, builder: (_) => CategoriesDialog(initial: categories)),
            icon: const Icon(Icons.label_outline),
            label: Text(l10n.dashContentCategories),
          ),
        FilledButton.icon(
          key: const Key('content-new'),
          onPressed: () => showDialog<void>(context: context, builder: (_) => const ContentDialog()),
          icon: const Icon(Icons.add),
          label: Text(l10n.dashNewItem),
        ),
      ],
      showClinic: false,
      children: [
        SegmentSwitch<String>(
          options: [
            ('all', l10n.dashContentAll),
            ('draft', l10n.dashDraft),
            ('published', l10n.dashPublished),
            ('archived', l10n.dashArchived),
          ],
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
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
                Builder(builder: (context) {
                  final content = ContentItem.fromMap('${item['id']}', item);
                  final status = '${item['status'] ?? 'draft'}';
                  return ActionRow(
                    key: Key('content-${item['id']}'),
                    leading: ContentThumb(item: content, width: 40),
                    title: content.title,
                    subtitle: [
                      categoryName(content.category),
                      content.isVideo ? l10n.dashTypeVideo : l10n.dashTypeTip,
                      '${l10n.dashOrder} ${content.order}',
                    ].join(' · '),
                    actions: [
                      if (content.proposed) ProposedBadge(key: Key('proposed-${item['id']}')),
                      StatusPill(statusLabel(l10n, status), switch (status) {
                        'published' => PillKind.ok,
                        'archived' => PillKind.noShow,
                        _ => PillKind.warn,
                      }),
                      IconButton(
                        key: Key('preview-${item['id']}'),
                        tooltip: l10n.dashPreview,
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => showContentPreview(context, content),
                      ),
                      if (status == 'draft' || isDoctor)
                        IconButton(
                          key: Key('edit-${item['id']}'),
                          tooltip: l10n.dashEdit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showDialog<void>(context: context, builder: (_) => ContentDialog(item: item)),
                        ),
                      if (isDoctor && status == 'draft')
                        statusAction(item, 'published', 'publish', l10n.dashPublish, l10n.dashPublished, filled: true),
                      if (isDoctor && status == 'published')
                        statusAction(item, 'draft', 'unpublish', l10n.dashUnpublish, l10n.dashUnpublished),
                      if (isDoctor && status != 'archived')
                        statusAction(item, 'archived', 'archive', l10n.dashArchive, l10n.dashArchived),
                      if (isDoctor && status == 'archived')
                        statusAction(item, 'draft', 'restore', l10n.dashRestore, l10n.dashRestored),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The channel's latest videos (`channelVideos`); picking one opens a new draft with its link.
class ChannelImportDialog extends ConsumerStatefulWidget {
  const ChannelImportDialog({super.key});

  @override
  ConsumerState<ChannelImportDialog> createState() => _ChannelImportDialogState();
}

class _ChannelImportDialogState extends ConsumerState<ChannelImportDialog> {
  late final Future<List<Map<String, dynamic>>> _videos = ref
      .read(dashboardApiProvider)
      .call('channelVideos', {})
      .then((r) => [for (final v in (r['videos'] as List? ?? const [])) Map<String, dynamic>.from(v as Map)]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return AlertDialog(
      title: Text(l10n.dashContentImport),
      content: SizedBox(
        width: 520,
        child: FutureBuilder(
          future: _videos,
          builder: (context, snap) {
            if (snap.hasError) return Text(l10n.dashImportError, key: const Key('import-error'));
            if (!snap.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.dashImportNote, style: TextStyle(fontSize: 12, color: c.muted)),
                const SizedBox(height: 8),
                for (final v in snap.data!)
                  ActionRow(
                    key: Key('import-row-${v['id']}'),
                    leading: ContentThumb(
                      item: ContentItem(id: '${v['id']}', type: ContentType.video, title: '', category: '', youtubeId: '${v['id']}'),
                      width: 40,
                    ),
                    title: '${v['title']}',
                    subtitle: '${v['published']}'.split('T').first,
                    actions: [
                      if (v['alreadyAdded'] == true)
                        StatusPill(l10n.dashImportAdded, PillKind.ok)
                      else
                        FilledButton.tonal(
                          key: Key('import-${v['id']}'),
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog<void>(
                              context: context,
                              builder: (_) => ContentDialog(initialUrl: 'https://youtube.com/shorts/${v['id']}'),
                            );
                          },
                          child: Text(l10n.dashAdd),
                        ),
                    ],
                  ),
              ]),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose))],
    );
  }
}

/// The doctor's category list (006 R5): rename, reorder, add; the server refuses removing one in use.
class CategoriesDialog extends ConsumerStatefulWidget {
  const CategoriesDialog({super.key, required this.initial});

  final List<ContentCategory> initial;

  @override
  ConsumerState<CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends ConsumerState<CategoriesDialog> {
  late final _rows = [for (final x in widget.initial) (id: x.id, name: TextEditingController(text: x.name))];

  @override
  void dispose() {
    for (final r in _rows) {
      r.name.dispose();
    }
    super.dispose();
  }

  void _move(int i, int by) => setState(() => _rows.insert(i + by, _rows.removeAt(i)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dashContentCategories),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, r) in _rows.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      key: Key('category-${r.id}'),
                      controller: r.name,
                      decoration: dashInput(context, hint: l10n.dashCategoryName),
                    ),
                  ),
                  IconButton(tooltip: l10n.dashMoveUp, onPressed: i == 0 ? null : () => _move(i, -1), icon: const Icon(Icons.arrow_upward)),
                  IconButton(
                    tooltip: l10n.dashMoveDown,
                    onPressed: i == _rows.length - 1 ? null : () => _move(i, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    key: Key('category-remove-${r.id}'),
                    tooltip: l10n.dashRemove,
                    onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ]),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('category-add'),
                onPressed: () => setState(
                  () => _rows.add((id: 'cat-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}', name: TextEditingController())),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.dashCategoryAdd),
              ),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('categories-save'),
          onPressed: () async {
            final ok = await runAction(
              context,
              () => ref.read(dashboardApiProvider).call('saveContentCategories', {
                'categories': [
                  for (final r in _rows)
                    if (r.name.text.trim().isNotEmpty) {'id': r.id, 'name': r.name.text.trim()},
                ],
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
