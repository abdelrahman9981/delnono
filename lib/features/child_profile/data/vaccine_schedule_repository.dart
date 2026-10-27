import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../domain/child_age.dart';

/// `vaccineSchedule/{e}`: one dose of the basic schedule (data-model.md, research R2).
class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.vaccineId,
    required this.dose,
    required this.dueAge,
    required this.ageLabel,
    required this.order,
    this.lastAge,
    this.proposed = false,
  });

  factory ScheduleEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return ScheduleEntry(
      id: s.id,
      vaccineId: d['vaccineId'] as String,
      dose: (d['dose'] as num?)?.toInt() ?? 1,
      dueAge: AgeSpan.fromMap(d['dueAge']),
      lastAge: d['lastAge'] == null ? null : AgeSpan.fromMap(d['lastAge']),
      ageLabel: d['ageLabel'] as String? ?? '',
      order: (d['order'] as num?)?.toInt() ?? 0,
      proposed: d['reviewStatus'] == 'proposed',
    );
  }

  /// Researched for the demo and not yet approved by the doctor (`reviewStatus: proposed`).
  final bool proposed;

  final String id;
  final String vaccineId;
  final int dose;
  final AgeSpan dueAge;

  /// After this age a dose not given is "missed"; null when the schedule sets no limit.
  final AgeSpan? lastAge;
  final String ageLabel;
  final int order;
}

enum VaccineKind { basic, additional }

/// `vaccines/{id}` with the schedule fields of 003 (the 002 catalogue, extended).
class VaccineInfo {
  const VaccineInfo({
    required this.id,
    required this.name,
    required this.kind,
    this.active = true,
    this.note,
    this.suggestedAge,
    this.doses = 1,
    this.intervalWeeks = 0,
    this.proposed = false,
  });

  factory VaccineInfo.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return VaccineInfo(
      id: s.id,
      name: d['name'] as String? ?? '',
      kind: d['kind'] == 'additional' ? VaccineKind.additional : VaccineKind.basic,
      active: d['active'] as bool? ?? true,
      note: d['note'] as String?,
      suggestedAge: d['suggestedAge'] == null ? null : AgeSpan.fromMap(d['suggestedAge']),
      doses: (d['doses'] as num?)?.toInt() ?? 1,
      intervalWeeks: (d['intervalWeeks'] as num?)?.toInt() ?? 0,
      proposed: d['reviewStatus'] == 'proposed',
    );
  }

  /// Researched for the demo and not yet approved by the doctor (`reviewStatus: proposed`).
  final bool proposed;

  final String id;
  final String name;
  final VaccineKind kind;
  final bool active;
  final String? note;
  final AgeSpan? suggestedAge;
  final int doses;
  final int intervalWeeks;
}

/// `settings/vaccines` (data-model.md). Defaults apply when missing.
class VaccineSettings {
  const VaccineSettings({this.source = '', this.reviewedOn, this.lateAfterDays = 7});

  factory VaccineSettings.fromMap(Map<String, dynamic>? d) => VaccineSettings(
    source: d?['source'] as String? ?? '',
    reviewedOn: d?['reviewedOn'] as String?,
    lateAfterDays: (d?['lateAfterDays'] as num?)?.toInt() ?? 7,
  );

  final String source;

  /// `YYYY-MM-DD` of the doctor's last review.
  final String? reviewedOn;
  final int lateAfterDays;
}

/// The basic schedule in order.
final vaccineScheduleProvider = StreamProvider<List<ScheduleEntry>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('vaccineSchedule')
      .snapshots()
      .map((q) => q.docs.map(ScheduleEntry.fromSnapshot).toList()..sort((a, b) => a.order.compareTo(b.order))),
);

/// The whole vaccine catalogue, by id (inactive ones too: a given dose keeps its name).
final vaccineCatalogueProvider = StreamProvider<Map<String, VaccineInfo>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('vaccines')
      .snapshots()
      .map((q) => {for (final d in q.docs) d.id: VaccineInfo.fromSnapshot(d)}),
);

final vaccineSettingsProvider = StreamProvider<VaccineSettings>(
  (ref) =>
      ref.watch(firestoreProvider).doc('settings/vaccines').snapshots().map((s) => VaccineSettings.fromMap(s.data())),
);
