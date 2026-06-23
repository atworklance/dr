import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/availability_window.dart';
import '../../domain/entities/provider_availability.dart';
import '../../domain/entities/time_range.dart';
import '../../domain/usecases/get_availability.dart';
import '../../domain/usecases/set_holiday_mode.dart';
import '../../domain/usecases/update_weekly_availability.dart';
import '../../domain/usecases/upsert_availability_exception.dart';

part 'availability_state.dart';

/// Manages the provider availability editor: loads the matrix, edits a working
/// draft of the weekly windows (with breaks), persists the schedule, toggles
/// Holiday Mode, and adds date exceptions.
class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit({
    required GetAvailability getAvailability,
    required UpdateWeeklyAvailability updateWeekly,
    required UpsertAvailabilityException upsertException,
    required SetHolidayMode setHolidayMode,
  })  : _getAvailability = getAvailability,
        _updateWeekly = updateWeekly,
        _upsertException = upsertException,
        _setHolidayMode = setHolidayMode,
        super(const AvailabilityState());

  final GetAvailability _getAvailability;
  final UpdateWeeklyAvailability _updateWeekly;
  final UpsertAvailabilityException _upsertException;
  final SetHolidayMode _setHolidayMode;

  Future<void> load() async {
    emit(state.copyWith(status: AvailabilityStatus.loading, clearError: true));
    final result = await _getAvailability();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AvailabilityStatus.error,
        errorMessage: failure.message,
      )),
      (availability) => emit(state.copyWith(
        status: AvailabilityStatus.ready,
        availability: availability,
        draftWindows: List.of(availability.weeklyAvailability),
        isDirty: false,
        clearError: true,
      )),
    );
  }

  // --- draft editing (local until saved) -----------------------------------

  void addWindow(int weekday, TimeRange range) {
    final draft = [
      ...state.draftWindows,
      AvailabilityWindow(
        weekday: weekday,
        startTime: range.startTime,
        endTime: range.endTime,
      ),
    ];
    emit(state.copyWith(draftWindows: draft, isDirty: true));
  }

  void removeWindow(AvailabilityWindow window) {
    final draft = [...state.draftWindows]..remove(window);
    emit(state.copyWith(draftWindows: draft, isDirty: true));
  }

  void addBreak(AvailabilityWindow window, TimeRange range) {
    _replaceWindow(
      window,
      window.copyWith(breaks: [...window.breaks, range]),
    );
  }

  void removeBreak(AvailabilityWindow window, TimeRange range) {
    _replaceWindow(
      window,
      window.copyWith(breaks: [...window.breaks]..remove(range)),
    );
  }

  void _replaceWindow(AvailabilityWindow oldWindow, AvailabilityWindow next) {
    final index = state.draftWindows.indexOf(oldWindow);
    if (index < 0) return;
    final draft = [...state.draftWindows];
    draft[index] = next;
    emit(state.copyWith(draftWindows: draft, isDirty: true));
  }

  void discardChanges() {
    final availability = state.availability;
    if (availability == null) return;
    emit(state.copyWith(
      draftWindows: List.of(availability.weeklyAvailability),
      isDirty: false,
    ));
  }

  // --- persistence ---------------------------------------------------------

  Future<void> saveWeekly() async {
    final availability = state.availability;
    if (availability == null || state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _updateWeekly(state.draftWindows);
    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        errorMessage: failure.message,
      )),
      (windows) => emit(state.copyWith(
        isSaving: false,
        isDirty: false,
        draftWindows: List.of(windows),
        availability: availability.copyWith(weeklyAvailability: windows),
      )),
    );
  }

  Future<void> setHolidayMode(bool enabled) async {
    final availability = state.availability;
    if (availability == null || state.isMutating) return;
    emit(state.copyWith(isMutating: true, clearError: true));

    final result = await _setHolidayMode(enabled);
    result.fold(
      (failure) => emit(state.copyWith(
        isMutating: false,
        errorMessage: failure.message,
      )),
      (value) => emit(state.copyWith(
        isMutating: false,
        availability: availability.copyWith(holidayMode: value),
      )),
    );
  }

  Future<void> addException(AvailabilityException exception) async {
    final availability = state.availability;
    if (availability == null || state.isMutating) return;
    emit(state.copyWith(isMutating: true, clearError: true));

    final result = await _upsertException(exception);
    result.fold(
      (failure) => emit(state.copyWith(
        isMutating: false,
        errorMessage: failure.message,
      )),
      (exceptions) => emit(state.copyWith(
        isMutating: false,
        availability: availability.copyWith(exceptions: exceptions),
      )),
    );
  }
}
