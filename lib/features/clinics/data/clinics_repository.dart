import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../domain/clinic_hours.dart';

/// `clinics/{id}` (004 data-model.md): one of the doctor's clinics, public to read (Home).
class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    this.phone,
    this.whatsapp,
    this.active = true,
    this.order = 0,
    this.workingHours = const {},
    this.packagePrice,
    this.packageMonths = 12,
  });

  factory Clinic.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const <String, dynamic>{};
    String? number(String key) {
      final v = (d[key] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return Clinic(
      id: s.id,
      name: d['name'] as String? ?? '',
      area: d['area'] as String? ?? '',
      address: d['address'] as String? ?? '',
      phone: number('phone'),
      whatsapp: number('whatsapp'),
      active: d['active'] as bool? ?? false,
      order: (d['order'] as num?)?.toInt() ?? 0,
      workingHours: parseWorkingHours(d['workingHours']) ?? const {},
      packagePrice: (d['packagePrice'] as num?)?.toInt(),
      packageMonths: (d['packageMonths'] as num?)?.toInt() ?? 12,
    );
  }

  final String id;
  final String name;

  /// Short place name for the clinic step, e.g. "المقطم".
  final String area;
  final String address;

  /// E.164 numbers; null hides the button.
  final String? phone;
  final String? whatsapp;
  final bool active;
  final int order;
  final Map<int, List<HourRange>> workingHours;

  /// The annual package at this clinic (D-45): price in EGP (null until set) and months.
  final int? packagePrice;
  final int packageMonths;
}

/// Every clinic, active or not, in display order. Inactive clinics are kept so old bookings and
/// visits still show their clinic's name and address.
final allClinicsProvider = StreamProvider<List<Clinic>>((ref) => ref
    .watch(firestoreProvider)
    .collection('clinics')
    .snapshots()
    .map((q) => q.docs.map(Clinic.fromSnapshot).toList()..sort((a, b) => a.order.compareTo(b.order))));

/// Clinics guardians can book and see on Home (FR-003).
final clinicsProvider = Provider<AsyncValue<List<Clinic>>>(
  (ref) => ref.watch(allClinicsProvider).whenData((all) => all.where((c) => c.active).toList()),
);

/// A clinic by id, active or not; null while loading or when unknown.
final clinicProvider = Provider.family<Clinic?, String>(
  (ref, id) => ref.watch(allClinicsProvider).value?.where((c) => c.id == id).firstOrNull,
);

/// The main clinic: the first active clinic in display order. Records without a clinic belong to
/// it (004 research R5).
final mainClinicProvider = Provider<Clinic?>((ref) => ref.watch(clinicsProvider).value?.firstOrNull);

/// The clinic of a stored record: its own, or the main clinic when the record has none.
final clinicOfProvider = Provider.family<Clinic?, String?>(
  (ref, id) => id == null ? ref.watch(mainClinicProvider) : ref.watch(clinicProvider(id)),
);
