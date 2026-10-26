import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/content/youtube.dart';
import '../../features/content/data/content_repository.dart';
import '../../features/content/domain/content_item.dart';
import '../../features/content/presentation/item_card.dart';
import '../data/dashboard_api.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// Add or edit a video or tip (006 US4). A pasted link is checked as typed: the YouTube id and
/// thumbnail show, anything else is refused (the server checks again). New items are drafts.
class ContentDialog extends ConsumerStatefulWidget {
  const ContentDialog({super.key, this.item, this.initialUrl});

  final Map<String, dynamic>? item;

  /// A link picked in «استيراد من القناة».
  final String? initialUrl;

  @override
  ConsumerState<ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends ConsumerState<ContentDialog> {
  late final Map<String, dynamic> _i = widget.item ?? const {};
  late final _title = TextEditingController(text: '${_i['title'] ?? ''}');
  late final _url = TextEditingController(text: widget.initialUrl ?? '${_i['url'] ?? ''}');
  late final _body = TextEditingController(text: '${_i['body'] ?? ''}');
  late final _from = TextEditingController(text: '${_i['ageFromMonths'] ?? 0}');
  late final _to = TextEditingController(text: '${_i['ageToMonths'] ?? 12}');
  late final _order = TextEditingController(text: '${_i['order'] ?? 100}');
  // New items start as a video: pasting a channel link is the usual case.
  late ContentType _type = widget.item == null ? ContentType.video : ContentItem.fromMap('', _i).type;
  late bool _aged = _i['ageFromMonths'] != null;
  late String? _category = _i['category'] as String?;

  String? get _youtubeId => youtubeIdFrom(_url.text);

  ContentItem get _draft => ContentItem(
    id: '${_i['id'] ?? 'preview'}',
    type: _type,
    title: _title.text.trim(),
    category: _category ?? '',
    body: _body.text.trim(),
    youtubeId: _type == ContentType.video ? _youtubeId : null,
    ageFromMonths: _aged ? int.tryParse(_from.text) : null,
    ageToMonths: _aged ? int.tryParse(_to.text) : null,
  );

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      _category != null &&
      (_type == ContentType.video ? _youtubeId != null : _body.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final c in [_title, _url, _body, _from, _to, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final categories = ref.watch(contentCategoriesProvider).value ?? defaultContentCategories;
    final id = _youtubeId;
    void changed(_) => setState(() {});
    Widget gap() => const SizedBox(height: 12);

    return AlertDialog(
      title: Text(widget.item == null ? l10n.dashNewItem : l10n.dashEdit),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            DashField(
              label: l10n.dashContentType,
              child: SegmentSwitch<ContentType>(
                options: [(ContentType.video, l10n.dashTypeVideo), (ContentType.tip, l10n.dashTypeTip)],
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
            gap(),
            DashField(
              label: l10n.dashItemTitle,
              child: TextField(
                key: const Key('content-title'),
                controller: _title,
                maxLength: 120,
                onChanged: changed,
                decoration: dashInput(context),
              ),
            ),
            DashField(
              label: l10n.dashCategory,
              child: DropdownButtonFormField<String>(
                key: const Key('content-category'),
                isExpanded: true,
                initialValue: categories.any((x) => x.id == _category) ? _category : null,
                items: [for (final x in categories) DropdownMenuItem(value: x.id, child: Text(x.name))],
                onChanged: (v) => setState(() => _category = v),
                decoration: dashInput(context),
              ),
            ),
            gap(),
            if (_type == ContentType.video) ...[
              DashField(
                label: l10n.dashYoutubeLink,
                child: TextField(
                  key: const Key('content-url'),
                  controller: _url,
                  textDirection: TextDirection.ltr,
                  onChanged: changed,
                  decoration: dashInput(context, hint: l10n.dashYoutubeHint),
                ),
              ),
              const SizedBox(height: 8),
              if (id != null)
                Row(key: const Key('content-video-ok'), children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      youtubeThumb(id),
                      key: const Key('content-thumb'),
                      width: 120,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(width: 120, height: 90, color: c.blueSoft),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.dashYoutubeId(id), textDirection: TextDirection.ltr, textAlign: TextAlign.end)),
                ])
              else if (_url.text.trim().isNotEmpty)
                Text(l10n.dashYoutubeInvalid, key: const Key('content-url-error'), style: TextStyle(color: c.dangerText)),
              gap(),
            ],
            DashField(
              label: l10n.dashBody,
              note: _type == ContentType.tip && _body.text.trim().isEmpty ? l10n.dashBodyRequired : null,
              child: TextField(
                key: const Key('content-body'),
                controller: _body,
                maxLines: 5,
                maxLength: 4000,
                onChanged: changed,
                decoration: dashInput(context),
              ),
            ),
            SwitchListTile(
              key: const Key('content-age-toggle'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dashAgeLimited),
              value: _aged,
              onChanged: (v) => setState(() => _aged = v),
            ),
            if (_aged)
              Row(children: [
                Expanded(
                  child: DashField(
                    label: l10n.dashAgeFrom,
                    child: TextField(key: const Key('content-age-from'), controller: _from, keyboardType: TextInputType.number, onChanged: changed, decoration: dashInput(context)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashField(
                    label: l10n.dashAgeTo,
                    child: TextField(key: const Key('content-age-to'), controller: _to, keyboardType: TextInputType.number, onChanged: changed, decoration: dashInput(context)),
                  ),
                ),
              ]),
            gap(),
            DashField(
              label: l10n.dashOrder,
              note: l10n.dashOrderNote,
              child: TextField(key: const Key('content-order'), controller: _order, keyboardType: TextInputType.number, decoration: dashInput(context)),
            ),
            const SizedBox(height: 8),
            Text(l10n.dashDraftNote, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        OutlinedButton(
          key: const Key('content-preview'),
          onPressed: _valid ? () => showContentPreview(context, _draft) : null,
          child: Text(l10n.dashPreview),
        ),
        FilledButton(
          key: const Key('content-save'),
          onPressed: !_valid
              ? null
              : () async {
                  final ok = await runAction(
                    context,
                    () => ref.read(dashboardApiProvider).call('saveContent', {
                      if (widget.item != null) 'id': widget.item!['id'],
                      'type': _type.name,
                      'title': _title.text.trim(),
                      'category': _category,
                      if (_type == ContentType.video) 'url': _url.text.trim(),
                      'body': _body.text.trim(),
                      'ageFromMonths': _aged ? int.tryParse(_from.text) : null,
                      'ageToMonths': _aged ? int.tryParse(_to.text) : null,
                      'order': int.tryParse(_order.text) ?? 100,
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

/// The item as a mother sees it: the library card, then the video frame or the tip's text.
Future<void> showContentPreview(BuildContext context, ContentItem item) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      key: const Key('content-preview-dialog'),
      title: Text(l10n.dashPreviewTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            ContentCard(item: item, preview: true),
            const SizedBox(height: 14),
            if (item.isVideo)
              Center(
                child: SizedBox(
                  width: 200,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: Colors.black,
                          child: Image.network(
                            'https://i.ytimg.com/vi/${item.youtubeId}/oardefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.network(youtubeThumb(item.youtubeId!), fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                          ),
                        ),
                      ),
                      const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56)),
                    ]),
                  ),
                ),
              )
            else ...[
              Text(item.title, style: text.titleMedium),
              const SizedBox(height: 8),
              Text(item.body ?? '', key: const Key('preview-body'), style: text.bodyMedium?.copyWith(height: 1.7)),
            ],
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose))],
    );
  },
);
