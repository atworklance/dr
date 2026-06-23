part of 'availability_cubit.dart';

enum AvailabilityStatus { initial, loading, ready, error }

class AvailabilityState extends Equatable {
  const AvailabilityState({
    this.status = AvailabilityStatus.initial,
    this.availability,
    this.draftWindows = const [],
    this.isDirty = false,
    this.isSaving = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final AvailabilityStatus status;
  final ProviderAvailability? availability;

  /// Editable working copy of the weekly windows.
  final List<AvailabilityWindow> draftWindows;
  final bool isDirty;
  final bool isSaving;
  final bool isMutating;
  final String? errorMessage;

  bool get isReady => status == AvailabilityStatus.ready && availability != null;

  List<AvailabilityWindow> draftForDay(int weekday) {
    final windows =
        draftWindows.where((w) => w.weekday == weekday).toList();
    windows.sort((a, b) => a.startTime.compareTo(b.startTime));
    return windows;
  }

  /// The index of [window] within [draftWindows] (identity by value position).
  int indexOf(AvailabilityWindow window) => draftWindows.indexOf(window);

  AvailabilityState copyWith({
    AvailabilityStatus? status,
    ProviderAvailability? availability,
    List<AvailabilityWindow>? draftWindows,
    bool? isDirty,
    bool? isSaving,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AvailabilityState(
      status: status ?? this.status,
      availability: availability ?? this.availability,
      draftWindows: draftWindows ?? this.draftWindows,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        availability,
        draftWindows,
        isDirty,
        isSaving,
        isMutating,
        errorMessage,
      ];
}
