import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/clock.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/age.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../children/data/children_repository.dart';
import '../../clinics/data/clinics_repository.dart';
import '../../clinics/presentation/clinic_photo.dart';
import '../../registration/data/guardian_repository.dart';
import '../application/booking_form_controller.dart';
import '../data/booking_api.dart';
import '../data/booking_settings.dart';
import '../data/packages_repository.dart';
import '../data/bookings_repository.dart';
import '../domain/booking.dart';
import '../data/slots_repository.dart';
import '../data/vaccines_repository.dart';
import '../domain/price_preview.dart';
import '../domain/schedule.dart';
import 'booking_format.dart';
import '../../../core/widgets/load_error.dart';

/// Booking (`/booking`, docs/design/figma/booking.jpg; FR-001 to FR-017). The guardian picks the
/// clinic first (004 FR-006); [initialClinicId] comes from a Home clinic card (`/booking?clinic=`).
/// With [changeBookingId] it changes an existing booking at its own clinic (`/booking/change/:id`).
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, this.changeBookingId, this.initialClinicId});

  final String? changeBookingId;
  final String? initialClinicId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _started = false;
  bool _preselected = false;

  /// Change mode: fills the form from the booking once it and its clinic have loaded (FR-022).
  void _startChange(Booking? booking, Clinic? clinic) {
    if (_started || booking == null || clinic == null) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(bookingFormProvider.notifier).start(editing: booking, clinicId: clinic.id);
    });
  }

  /// A new booking starts at the clinic from Home, the guardian's preferred clinic («حسابي»), or
  /// the only active clinic (004 FR-006). "Change clinic" still shows them all.
  void _preselect(List<Clinic> clinics) {
    if (_preselected || widget.changeBookingId != null) return;
    _preselected = true;
    final preferred = ref.read(guardianProvider).value?.preferredClinicId;
    Clinic? byId(String? id) => clinics.where((c) => c.id == id).firstOrNull;
    final wanted = byId(widget.initialClinicId) ?? byId(preferred) ?? (clinics.length == 1 ? clinics.first : null);
    if (wanted == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(bookingFormProvider.notifier).setClinic(wanted.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clinics = ref.watch(clinicsProvider);
    final children = ref.watch(childrenProvider);
    final changeId = widget.changeBookingId;
    if (changeId != null) {
      final booking = ref.watch(bookingByIdProvider(changeId));
      _startChange(booking, booking == null ? null : ref.watch(clinicOfProvider(booking.clinicId)));
      if (ref.watch(bookingFormProvider).editing == null) {
        return Scaffold(appBar: _appBar(l10n), body: const Center(child: CircularProgressIndicator()));
      }
    }
    // The guardian's profile too, so the preferred clinic is known before the first choice.
    final guardian = ref.watch(guardianProvider);
    // A failed read is not "no children": say so with a retry, never the add-child gate (bug 0003).
    if (children.hasError || clinics.hasError) {
      return Scaffold(
        appBar: _appBar(l10n),
        body: LoadErrorView(onRetry: () {
          ref.invalidate(childrenProvider);
          ref.invalidate(clinicsProvider);
        }),
      );
    }
    if (!clinics.hasValue || !children.hasValue || !guardian.hasValue) {
      return Scaffold(appBar: _appBar(l10n), body: const Center(child: CircularProgressIndicator()));
    }
    _preselect(clinics.value!);
    final clinicId = ref.watch(bookingFormProvider).clinicId;
    if (clinicId == null && children.value!.isNotEmpty) {
      return Scaffold(appBar: _appBar(l10n), body: SafeArea(child: _ClinicStep(clinics: clinics.value!)));
    }
    final settings = clinicId == null ? null : ref.watch(bookingSettingsProvider(clinicId));
    if (settings != null && !settings.hasValue) {
      return Scaffold(appBar: _appBar(l10n), body: const Center(child: CircularProgressIndicator()));
    }
    if (children.value!.isEmpty) {
      return Scaffold(
        appBar: _appBar(l10n),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.noChildrenToBook, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.push(Routes.childrenAdd), child: Text(l10n.childrenAdd)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: _appBar(l10n),
      body: SafeArea(
        child: _BookingForm(
          clinic: ref.watch(clinicProvider(clinicId!)),
          clinicId: clinicId,
          canChangeClinic: changeId == null && clinics.value!.length > 1,
          settings: settings!.value!,
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(AppLocalizations l10n) => AppBar(
        title: Text(widget.changeBookingId == null ? l10n.bookingTitle : l10n.changeTitle),
        automaticallyImplyLeading: widget.changeBookingId != null,
        actions: [
          if (widget.changeBookingId == null)
            TextButton(
              key: const Key('my-bookings-action'),
              onPressed: () => context.go('${Routes.booking}/mine'),
              child: Text(l10n.myBookings),
            ),
        ],
      );
}

/// Step 0 (004 FR-006): one card per active clinic.
class _ClinicStep extends ConsumerWidget {
  const _ClinicStep({required this.clinics});

  final List<Clinic> clinics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _Section(title: l10n.chooseClinic),
        if (clinics.isEmpty) Text(l10n.noClinics, style: text.bodyMedium?.copyWith(color: c.muted)),
        for (final clinic in clinics) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClinicPhoto(clinic: clinic, height: 120),
                ListTile(
                  key: Key('clinic-${clinic.id}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: c.blueSoft,
                    foregroundColor: c.blue,
                    child: const Icon(Icons.location_on_outlined),
                  ),
                  title: Text(clinic.name, style: text.titleSmall),
                  subtitle: Text(clinic.address, style: text.bodySmall),
                  // chevron_right mirrors with the text direction: it points left (‹, forward) in RTL.
                  trailing: Icon(Icons.chevron_right, color: c.muted),
                  onTap: () => ref.read(bookingFormProvider.notifier).setClinic(clinic.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BookingForm extends ConsumerWidget {
  const _BookingForm({required this.clinic, required this.clinicId, required this.canChangeClinic, required this.settings});

  final Clinic? clinic;
  final String clinicId;
  final bool canChangeClinic;
  final BookingSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final form = ref.watch(bookingFormProvider);
    final controller = ref.read(bookingFormProvider.notifier);
    final now = ref.watch(clockProvider)();
    final kids = ref.watch(childrenProvider).value ?? const [];
    final vaccines = ref.watch(vaccinesProvider(clinicId)).value ?? const <Vaccine>[];
    final vaccineOnly = form.visitType == VisitType.vaccineOnly;
    final days = bookableDays(settings, now, vaccines: vaccineOnly);
    final date = form.date;
    final vaccinesAllowed = date != null && isVaccineDay(settings, date);
    final taken = date == null
        ? const <int, int>{}
        : (ref.watch(slotsTakenProvider((clinicId: clinicId, date: date))).value ?? const {});
    // The family's package covering the chosen day, if any (feature 006, FR-016).
    final packageId = date == null || vaccineOnly ? null : ref.watch(activePackageProvider(date)).value;

    final preview = previewPrice(
      visitType: form.visitType,
      vaccinesByChild: {for (final id in form.children) id: form.vaccines[id] ?? const []},
      visitPrice: settings.visitPrice,
      vaccines: {for (final v in vaccines) v.id: v},
      packageId: packageId,
      previous: form.editing?.price,
    );
    final step = form.hour == null ? 1 : (form.children.isEmpty ? 2 : 3);

    Future<void> confirm() async {
      final result = await controller.submit(preview.total);
      if (result == null || !context.mounted) return;
      if (form.editing != null) {
        showAppMessage(l10n.bookingChanged);
        context.go('${Routes.booking}/mine');
      } else {
        context.go('${Routes.booking}/done/${result.bookingId}');
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        StepIndicator(current: step, total: 3),
        // The chosen clinic (004 FR-006); "تغيير" goes back to the clinic step.
        if (clinic != null)
          Card(
            key: const Key('chosen-clinic'),
            child: ListTile(
              leading: Icon(Icons.location_on_outlined, color: c.blue),
              title: Text(clinic!.name, style: text.titleSmall),
              subtitle: Text(clinic!.address, style: text.bodySmall),
              trailing: canChangeClinic
                  ? TextButton(
                      key: const Key('change-clinic'),
                      onPressed: () => controller.setClinic(null),
                      child: Text(l10n.changeClinic),
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 8),
        // Visit type.
        Row(
          children: [
            Expanded(
              child: _Choice(
                key: const Key('type-visit'),
                selected: !vaccineOnly,
                icon: Icons.favorite_border,
                title: l10n.visitTypeVisit,
                subtitle: egp(l10n, settings.visitPrice),
                onTap: () => controller.setVisitType(VisitType.visit),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                key: const Key('type-vaccine'),
                selected: vaccineOnly,
                icon: Icons.vaccines_outlined,
                title: l10n.visitTypeVaccine,
                subtitle: l10n.visitTypeVaccineSub,
                onTap: () => controller.setVisitType(VisitType.vaccineOnly),
              ),
            ),
          ],
        ),
        _Section(title: l10n.chooseDay, trailing: days.isEmpty ? null : monthYear(days.first)),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final d = days[i];
              final selected = d == date;
              return _DayChip(
                key: Key('day-$d'),
                weekday: weekdayName(d),
                day: dayNumber(d),
                vaccineDay: isVaccineDay(settings, d),
                selected: selected,
                onTap: () => controller.setDate(d, settings),
              );
            },
          ),
        ),
        _Section(title: l10n.chooseHour, trailing: l10n.arrivalOrder),
        if (date == null)
          const SizedBox.shrink()
        else if (openHours(settings, date, now).isEmpty)
          Text(l10n.noHoursThatDay, style: text.bodyMedium?.copyWith(color: c.muted))
        else
          LayoutBuilder(
            builder: (context, box) {
              final columns = (box.maxWidth / 92).floor().clamp(2, 4);
              final width = (box.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in openHours(settings, date, now))
                    SizedBox(
                      width: width,
                      child: _HourCard(
                        key: Key('hour-$h'),
                        label: hourRange(l10n, h),
                        // Changing within the same hour keeps its own place.
                        left: placesLeft(settings, (taken[h] ?? 0) - (form.editing?.date == date && form.editing?.hour == h ? 1 : 0)),
                        capacity: settings.capacityPerHour,
                        selected: form.hour == h,
                        onTap: () => controller.setHour(h),
                      ),
                    ),
                ],
              );
            },
          ),
        _Section(title: l10n.whoIsComing, trailing: l10n.chooseMoreThanOne),
        for (final child in kids) ...[
          _ChildCard(
            key: Key('child-${child.id}'),
            name: child.name,
            age: arabicAge(child.birthDate, l10n),
            selected: form.children.contains(child.id),
            onTap: () => controller.toggleChild(child.id),
          ),
          if ((vaccinesAllowed || vaccineOnly) && form.children.contains(child.id) && vaccines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.vaccinesFor(child.name), style: text.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in vaccines)
                        FilterChip(
                          key: Key('vaccine-${child.id}-${v.id}'),
                          label: Text('${v.name} · ${v.showPrice ? egp(l10n, v.price) : l10n.priceAtClinic}'),
                          selected: form.vaccines[child.id]?.contains(v.id) ?? false,
                          onSelected: (_) => controller.toggleVaccine(child.id, v.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (form.selection != null) ...[
          const SizedBox(height: 8),
          _Summary(
            settings: settings,
            form: form,
            preview: preview,
            childName: {for (final k in kids) k.id: k.name},
          ),
          // No package covers this visit: point to the annual package (008 FR-004).
          if (!vaccineOnly && packageId == null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('package-hint'),
                onPressed: () => context.push(Routes.package),
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: Text(l10n.pkgBookingHint),
              ),
            ),
        ],
        if (form.error != null) ...[
          const SizedBox(height: 12),
          Notice(_errorText(l10n, form.error!), kind: NoticeKind.danger),
        ],
        if (vaccineOnly && form.selection != null && !form.anyVaccine) ...[
          const SizedBox(height: 12),
          Notice(l10n.bookingVaccineRequired, kind: NoticeKind.warn),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('confirm-booking'),
          onPressed: form.complete && !form.submitting ? confirm : null,
          child: form.submitting
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(form.editing == null ? l10n.confirmBooking : l10n.confirmChange),
        ),
      ],
    );
  }

  String _errorText(AppLocalizations l10n, Object e) => switch (e) {
        BookingFullException() => l10n.bookingFull,
        BookingPriceChangedException(:final price) => l10n.priceChanged(arabicDigits(price.total)),
        BookingSameDayException() => l10n.bookingAlreadyThatDay,
        BookingLimitException() => l10n.bookingTooMany,
        BookingRefusedException(reason: 'closed') => l10n.bookingClosedDay,
        BookingRefusedException(reason: 'not_vaccine_day') => l10n.bookingNotVaccineDay,
        BookingRefusedException(reason: 'beyond_horizon') => l10n.bookingBeyondHorizon,
        BookingRefusedException(reason: 'clinic_inactive') => l10n.bookingClinicInactive,
        BookingRefusedException() => l10n.bookingStarted,
        _ => arabicErrorMessage(e, l10n),
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: text.titleLarge)),
          if (trailing != null) Flexible(child: Text(trailing!, style: text.bodySmall, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final fg = selected ? c.blue : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? c.blueSoft : c.surface,
            border: Border.all(color: selected ? c.blueSoft : c.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? c.blue : c.text)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: fg)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({super.key, required this.weekday, required this.day, required this.vaccineDay, required this.selected, required this.onTap});

  final String weekday;
  final String day;
  final bool vaccineDay;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final fg = selected ? Colors.white : c.text;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 66,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.blue : c.surface,
            border: Border.all(color: selected ? c.blue : c.border),
            borderRadius: BorderRadius.circular(18),
          ),
          // Scales down as a whole so large system text never overflows the chip.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(weekday, style: TextStyle(fontSize: 11, color: selected ? Colors.white : c.muted)),
                Text(day, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 4),
                // Vaccine days are marked with a dot, as in the design.
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: vaccineDay ? (selected ? Colors.white : c.pink) : Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourCard extends StatelessWidget {
  const _HourCard({super.key, required this.label, required this.left, required this.capacity, required this.selected, required this.onTap});

  final String label;
  final int left;
  final int capacity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final full = left == 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      enabled: !full,
      selected: selected,
      child: InkWell(
        onTap: full ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: full ? c.border.withValues(alpha: .35) : (selected ? c.blueSoft : c.surface),
            border: Border.all(color: selected ? c.blue : c.border, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              FittedBox(
                child: Text(label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: full ? c.muted : c.text)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  full ? l10n.hourFull : l10n.placesLeft(arabicDigits(left), arabicDigits(capacity)),
                  style: TextStyle(
                    fontSize: 11,
                    color: full ? c.dangerText : (dark ? const Color(0xFF79D8BC) : const Color(0xFF1F7A61)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({super.key, required this.name, required this.age, required this.selected, required this.onTap});

  final String name;
  final String age;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: selected ? c.blue : c.border, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: c.blueSoft,
                foregroundColor: c.blue,
                child: Text(name.characters.first, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(age, style: TextStyle(fontSize: 11, color: c.muted)),
                  ],
                ),
              ),
              Checkbox(value: selected, onChanged: (_) => onTap()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.settings, required this.form, required this.preview, required this.childName});

  final BookingSettings settings;
  final BookingForm form;
  final PriceSnapshot preview;
  final Map<String, String> childName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF79D8BC) : const Color(0xFF1F7A61);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: c.muted))),
              const SizedBox(width: 8),
              Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
        );

    final covered = preview.visitCovered;
    return Card(
      key: const Key('booking-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.summaryTotal, style: text.bodySmall),
                      Text(
                        covered && preview.total == 0 ? l10n.coveredByPackage : egp(l10n, preview.total),
                        key: const Key('summary-total'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: covered ? green : c.text),
                      ),
                    ],
                  ),
                ),
                if (covered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(20)),
                    child: Text(l10n.activePackage, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
                  ),
              ],
            ),
            const Divider(height: 24),
            row(l10n.summaryWhen, '${dayLabel(form.date!)} · ${hourRange(l10n, form.hour!)}'),
            row(l10n.summaryChildren, joinNames(l10n, form.children.map((id) => childName[id] ?? ''))),
            if (preview.visitAmount != null)
              row(l10n.summaryVisit, covered ? l10n.coveredByPackage : egp(l10n, preview.visitAmount!)),
            for (final line in preview.vaccines)
              row('${line.name} · ${childName[line.childId] ?? ''}', line.shown ? egp(l10n, line.amount) : l10n.priceAtClinic),
            row(l10n.summaryPayment, l10n.cashAtClinic),
            if (preview.hasHiddenPrices) Text(l10n.totalExcludesHidden, style: text.bodySmall),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: c.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.cancelUntil(l10n.hoursCount(settings.cancelWindowHours, arabicDigits(settings.cancelWindowHours))),
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
