import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/booking_api.dart';
import '../data/booking_settings.dart';
import '../domain/booking.dart';
import '../domain/price_preview.dart';
import '../domain/schedule.dart';

@immutable
class BookingForm {
  const BookingForm({
    this.visitType = VisitType.visit,
    this.date,
    this.hour,
    this.children = const [],
    this.vaccines = const {},
    this.submitting = false,
    this.error,
    this.editing,
  });

  final VisitType visitType;
  final String? date;
  final int? hour;

  /// Child ids in the order picked.
  final List<String> children;

  /// Child id → vaccine ids.
  final Map<String, List<String>> vaccines;
  final bool submitting;
  final Object? error;

  /// The booking being changed, if any (FR-022).
  final Booking? editing;

  bool get anyVaccine => vaccines.values.any((v) => v.isNotEmpty);

  BookingSelection? get selection => date == null || hour == null || children.isEmpty
      ? null
      : BookingSelection(
          visitType: visitType,
          date: date!,
          hour: hour!,
          children: {for (final c in children) c: vaccines[c] ?? const []},
        );

  bool get complete => selection != null && (visitType == VisitType.visit || anyVaccine);

  BookingForm copyWith({
    VisitType? visitType,
    String? date,
    int? hour,
    List<String>? children,
    Map<String, List<String>>? vaccines,
    bool? submitting,
    Object? error,
    bool clearDate = false,
    bool clearHour = false,
    bool clearError = false,
  }) =>
      BookingForm(
        visitType: visitType ?? this.visitType,
        date: clearDate ? null : (date ?? this.date),
        hour: clearHour || clearDate ? null : (hour ?? this.hour),
        children: children ?? this.children,
        vaccines: vaccines ?? this.vaccines,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
        editing: editing,
      );
}

/// The booking screen's selection, validation and submit (FR-001 to FR-016).
class BookingFormController extends Notifier<BookingForm> {
  @override
  BookingForm build() => const BookingForm();

  /// Starts a new booking, or a change of [editing] pre-filled with its selection.
  void start({Booking? editing}) {
    state = editing == null
        ? const BookingForm()
        : BookingForm(
            visitType: editing.visitType,
            date: editing.date,
            hour: editing.hour,
            children: [for (final c in editing.children) c.childId],
            vaccines: {for (final c in editing.children) c.childId: c.vaccines},
            editing: editing,
          );
  }

  void setVisitType(VisitType type) {
    if (type == state.visitType) return;
    state = state.copyWith(visitType: type, clearDate: true, vaccines: const {}, clearError: true);
  }

  /// Picking a day clears the hour; vaccines are dropped on a day that is not a vaccine day.
  void setDate(String date, BookingSettings settings) {
    state = state.copyWith(
      date: date,
      clearHour: true,
      vaccines: isVaccineDay(settings, date) ? state.vaccines : const {},
      clearError: true,
    );
  }

  void setHour(int hour) => state = state.copyWith(hour: hour, clearError: true);

  void toggleChild(String childId) {
    final picked = [...state.children];
    final vaccines = {...state.vaccines};
    if (picked.remove(childId)) {
      vaccines.remove(childId);
    } else {
      picked.add(childId);
    }
    state = state.copyWith(children: picked, vaccines: vaccines, clearError: true);
  }

  void toggleVaccine(String childId, String vaccineId) {
    final list = [...?state.vaccines[childId]];
    list.contains(vaccineId) ? list.remove(vaccineId) : list.add(vaccineId);
    state = state.copyWith(vaccines: {...state.vaccines, childId: list}, clearError: true);
  }

  /// Confirms the shown total. Returns the result, or null with [BookingForm.error] set.
  Future<BookingResult?> submit(int shownTotal) async {
    final selection = state.selection;
    if (selection == null || !state.complete || state.submitting) return null;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final api = ref.read(bookingApiProvider);
      final editing = state.editing;
      final result = editing == null
          ? await api.create(selection, shownTotal)
          : await api.change(editing.id, selection, shownTotal);
      state = state.copyWith(submitting: false);
      return result;
    } on BookingFullException catch (e) {
      // The hour filled: pick another one; the rest of the selection stays (FR-009).
      state = state.copyWith(submitting: false, clearHour: true, error: e);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e);
    }
    return null;
  }
}

final bookingFormProvider = NotifierProvider.autoDispose<BookingFormController, BookingForm>(BookingFormController.new);
