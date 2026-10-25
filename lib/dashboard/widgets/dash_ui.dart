import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/format/arabic_digits.dart';

/// Dashboard colours from docs/design/dashboard/dash.css: the app's tokens plus the navy sidebar.
abstract final class Dash {
  static const navy = Color(0xFF16324B);
  static const navy2 = Color(0xFF1F4060);
  static const navyLine = Color(0xFF2A4A68);
  static const navyText = Color(0xFFC9D8E4);
  static const navyMuted = Color(0xFF8AA3B8);
  static const canvasLight = Color(0xFFF4F2EC);
  static const tableHead = Color(0xFFFAF9F6);
  static const walkInBg = Color(0xFFEDE9FB);
  static const walkInText = Color(0xFF5B46A8);
  static const greenText = Color(0xFF1F7A61);
  static const yellowText = Color(0xFF7D5800);
  static const pinkText = Color(0xFFB04A65);
  static const barTrack = Color(0xFFEEECE6);
}

/// Tones for icon chips and soft buttons (`.blue`, `.green`, `.pink`, `.yellow`, `.navy`).
enum Tone { blue, green, pink, yellow, navy }

(Color, Color) toneColors(BuildContext context, Tone t) {
  final c = Theme.of(context).extension<AppColors>()!;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (t) {
    Tone.blue => (c.blueSoft, dark ? c.blueDeep : const Color(0xFF237DB8)),
    Tone.green => (c.greenSoft, dark ? c.green : Dash.greenText),
    Tone.pink => (c.pinkSoft, dark ? c.pink : Dash.pinkText),
    Tone.yellow => (c.yellowSoft, dark ? c.yellow : Dash.yellowText),
    Tone.navy => (dark ? c.border : const Color(0xFFE8EEF3), dark ? c.text : Dash.navy),
  };
}

class IconChip extends StatelessWidget {
  const IconChip(this.icon, {super.key, this.tone = Tone.blue});

  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: fg),
    );
  }
}

/// `.card` with a `.card-head` row: each section has its own header, so titles never overlap fields.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    this.title,
    this.hint,
    this.icon,
    this.tone = Tone.blue,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    required this.child,
  });

  final String? title;
  final String? hint;
  final IconData? icon;
  final Tone tone;
  final Widget? action;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final text = Theme.of(context).textTheme;
    // A Material, so list tiles and ink inside the card paint on it.
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Row(children: [
                if (icon != null) ...[IconChip(icon!, tone: tone), const SizedBox(width: 10)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title!, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (hint != null) Text(hint!, style: text.bodySmall?.copyWith(color: c.muted)),
                  ]),
                ),
                // A wide action (e.g. many hour tabs) scrolls instead of pushing the title out.
                if (action != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: action),
                    ),
                  ),
                ],
              ]),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Booking and queue statuses (`.pill`): confirmed blue, arrived yellow, done green, no-show red,
/// walk-in purple.
enum PillKind { confirmed, arrived, done, noShow, walkIn, info, ok, warn }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.kind, {super.key, this.dot = true});

  final String label;
  final PillKind kind;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch (kind) {
      PillKind.confirmed || PillKind.info => (c.blueSoft, dark ? c.blueDeep : const Color(0xFF237DB8)),
      PillKind.arrived || PillKind.warn => (c.yellowSoft, dark ? c.yellow : Dash.yellowText),
      PillKind.done || PillKind.ok => (c.greenSoft, dark ? c.green : Dash.greenText),
      PillKind.noShow => (c.dangerBg, c.dangerText),
      PillKind.walkIn => (dark ? const Color(0xFF2E2950) : Dash.walkInBg, dark ? const Color(0xFFC3B6F5) : Dash.walkInText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[Container(width: 7, height: 7, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)), const SizedBox(width: 6)],
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ),
      ]),
    );
  }
}

/// A KPI tile (`.kpi`): label, big number with an optional unit, and a note.
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.label, required this.value, this.unit, this.note, this.color});

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: TextStyle(fontSize: 26, height: 1.1, fontWeight: FontWeight.w700, color: color ?? c.text)),
            if (unit != null) ...[const SizedBox(width: 6), Text(unit!, style: TextStyle(fontSize: 13, color: c.muted))],
          ]),
        ),
        if (note != null) ...[const SizedBox(height: 6), Text(note!, style: TextStyle(fontSize: 12, color: c.muted))],
      ]),
    );
  }
}

/// A responsive grid of equal tiles: [columns] across when there is room, fewer when narrow.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.columns = 5, this.minTileWidth = 170, this.gap = 14});

  final List<Widget> children;
  final int columns;
  final double minTileWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final fit = ((box.maxWidth + gap) / (minTileWidth + gap)).floor().clamp(1, columns);
        final width = (box.maxWidth - gap * (fit - 1)) / fit;
        return Wrap(spacing: gap, runSpacing: gap, children: [for (final c in children) SizedBox(width: width, child: c)]);
      });
}

/// The page's top bar (`.topbar`): title, subtitle, actions; the doctor's clinic switch sits here.
class DashTopBar extends StatelessWidget {
  const DashTopBar({super.key, required this.title, this.subtitle, this.leading, this.actions = const []});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.border))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 13, color: c.muted)),
              ]),
            ),
          ]),
          Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
        ],
      ),
    );
  }
}

/// `.clinic-switch`: segmented choice of clinics.
class SegmentSwitch<T> extends StatelessWidget {
  const SegmentSwitch({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.canvas, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
      // A Wrap, so long labels or many options take a second line instead of overflowing.
      child: Wrap(runSpacing: 4, children: [
        for (final (v, label) in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              key: ValueKey('segment-$v'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: v == value ? c.surface : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: v == value ? const [BoxShadow(color: Color(0x1416324B), blurRadius: 4, offset: Offset(0, 1))] : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: v == value ? c.text : c.muted, fontWeight: v == value ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A labelled field (`.field`): bold label above, optional note below.
class DashField extends StatelessWidget {
  const DashField({super.key, required this.label, required this.child, this.note});

  final String label;
  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      child,
      if (note != null) ...[const SizedBox(height: 4), Text(note!, style: TextStyle(fontSize: 12, color: c.muted))],
    ]);
  }
}

/// An input with an optional unit at the end (`.input` + `.unit`).
InputDecoration dashInput(BuildContext context, {String? hint, String? unit}) {
  final c = Theme.of(context).extension<AppColors>()!;
  OutlineInputBorder b(Color color) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color));
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    suffixText: unit,
    suffixStyle: TextStyle(fontSize: 13, color: c.muted),
    border: b(c.border),
    enabledBorder: b(c.border),
    focusedBorder: b(c.blue),
  );
}

/// The sticky save bar (`.save-bar`): shows unsaved changes; Save is never clipped.
class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.dirty, required this.onSave, required this.onDiscard, this.busy = false});

  final bool dirty;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      key: const Key('save-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      child: Row(children: [
        if (dirty) ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.yellow, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(child: Text(l10n.dashUnsaved, key: const Key('unsaved-note'), overflow: TextOverflow.ellipsis)),
        ] else
          Flexible(child: Text(l10n.dashAllSaved, style: TextStyle(color: c.muted), overflow: TextOverflow.ellipsis)),
        const Spacer(),
        OutlinedButton(key: const Key('discard'), onPressed: dirty && !busy ? onDiscard : null, child: Text(l10n.dashDiscard)),
        const SizedBox(width: 10),
        FilledButton(key: const Key('save-changes'), onPressed: dirty && !busy ? onSave : null, child: Text(l10n.dashSaveChanges)),
      ]),
    );
  }
}

/// `.tabs`: underlined tabs.
class DashTabs extends StatelessWidget {
  const DashTabs({super.key, required this.tabs, required this.index, required this.onChanged});

  final List<Widget> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final (i, t) in tabs.indexed)
            InkWell(
              key: Key('tab-$i'),
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == index ? c.blue : Colors.transparent, width: 2))),
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 14, color: i == index ? c.text : c.muted, fontWeight: i == index ? FontWeight.w600 : FontWeight.w400),
                  child: t,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// A simple table (`.table`): a tinted header row and rows separated by lines; cells flex by [flex].
/// Narrower than [stackBelow], each row wraps its cells instead, so nothing is squeezed.
class DashTable extends StatelessWidget {
  const DashTable({super.key, required this.headers, required this.flex, required this.rows, this.stackBelow = 720});

  final List<String> headers;
  final List<int> flex;
  final List<DashRow> rows;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, box) {
      final stacked = box.maxWidth < stackBelow;
      Widget line(List<Widget> cells, {Key? key, Color? color}) => Container(
            key: key,
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: stacked
                ? Wrap(spacing: 14, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: cells)
                : Row(children: [
                    for (final (i, cell) in cells.indexed)
                      Expanded(
                        flex: flex[i],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Align(alignment: AlignmentDirectional.centerStart, child: cell),
                        ),
                      ),
                  ]),
          );
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!stacked)
          line([for (final h in headers) Text(h, style: TextStyle(fontSize: 12, color: c.muted))], color: dark ? c.canvas : Dash.tableHead),
        for (final (i, r) in rows.indexed) ...[
          if (i > 0 || !stacked) Divider(height: 1, color: c.border),
          line(r.cells, key: r.key),
        ],
      ]);
    });
  }
}

class DashRow {
  const DashRow({this.key, required this.cells});

  final Key? key;
  final List<Widget> cells;
}

/// The child's or family's initial in a soft circle (`.avatar`).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.tone = Tone.blue, this.size = 36});

  final String name;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(name.isEmpty ? '·' : name.characters.first, style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: size * 0.4)),
    );
  }
}

/// A time-range chip (`.chip.time`), e.g. "٥ م ← ٩ م".
class TimeChip extends StatelessWidget {
  const TimeChip({super.key, required this.label, this.onTap, this.onRemove});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, Tone.blue);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              InkWell(onTap: onRemove, child: Icon(Icons.close, size: 14, color: fg)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// A dashed "+ add" chip (`.chip.add`).
class AddChip extends StatelessWidget {
  const AddChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(10)),
        child: Text('+ $label', style: TextStyle(fontSize: 12, color: c.muted)),
      ),
    );
  }
}

/// "٥ م" for an hour of the day (0–24).
String hourLabel(AppLocalizations l10n, int h) {
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${arabicDigits(h12)} ${h < 12 || h == 24 ? l10n.periodAm : l10n.periodPm}';
}

/// Picks a time range from lists of whole hours (start → end), never typed (README rule).
Future<(int, int)?> pickTimeRange(BuildContext context, {int from = 17, int to = 21}) => showDialog<(int, int)>(
      context: context,
      builder: (context) => _TimeRangeDialog(from: from, to: to),
    );

class _TimeRangeDialog extends StatefulWidget {
  const _TimeRangeDialog({required this.from, required this.to});

  final int from;
  final int to;

  @override
  State<_TimeRangeDialog> createState() => _TimeRangeDialogState();
}

class _TimeRangeDialogState extends State<_TimeRangeDialog> {
  late int _from = widget.from;
  late int _to = widget.to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dashPickRange),
      content: SizedBox(
        width: 320,
        child: Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: const Key('range-from'),
              isExpanded: true,
              initialValue: _from,
              items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text(hourLabel(l10n, h)))],
              onChanged: (h) => setState(() {
                _from = h!;
                if (_to <= _from) _to = _from + 1;
              }),
              decoration: InputDecoration(labelText: l10n.dashFrom),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('←')),
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey('range-to-$_from'),
              isExpanded: true,
              initialValue: _to,
              items: [for (var h = _from + 1; h <= 24; h++) DropdownMenuItem(value: h, child: Text(hourLabel(l10n, h)))],
              onChanged: (h) => setState(() => _to = h!),
              decoration: InputDecoration(labelText: l10n.dashTo),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(key: const Key('range-ok'), onPressed: () => Navigator.pop(context, (_from, _to)), child: Text(l10n.dashAdd)),
      ],
    );
  }
}

/// A date chosen from the date picker (never typed), shown as "الأحد، ١٥ نوفمبر ٢٠٢٦"; [value] and
/// [onChanged] use yyyy-MM-dd. With [onClear], an empty field means "any date".
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.first,
    required this.last,
    this.onClear,
    this.hint,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final DateTime first;
  final DateTime last;
  final VoidCallback? onClear;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final v = value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final initial = v == null ? last : DateTime.parse(v);
        final picked = await showDatePicker(
          context: context,
          firstDate: first,
          lastDate: last,
          initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
        );
        if (picked != null) {
          onChanged('${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: dashInput(context).copyWith(
          suffixIcon: v != null && onClear != null
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          v == null ? (hint ?? '') : arabicDigits(DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.parse(v))),
          overflow: TextOverflow.ellipsis,
          style: v == null ? TextStyle(color: c.muted) : null,
        ),
      ),
    );
  }
}
