part of 'specialist_search_bloc.dart';

sealed class SpecialistSearchEvent extends Equatable {
  const SpecialistSearchEvent();

  @override
  List<Object?> get props => const [];
}

/// Starts a new search from page one with the given [filter].
class SpecialistSearchRequested extends SpecialistSearchEvent {
  const SpecialistSearchRequested(this.filter);

  final SearchFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Loads the next page and appends it to the current results (infinite scroll).
class SpecialistSearchMoreRequested extends SpecialistSearchEvent {
  const SpecialistSearchMoreRequested();
}

/// Re-runs the active filter from page one (pull-to-refresh).
class SpecialistSearchRefreshed extends SpecialistSearchEvent {
  const SpecialistSearchRefreshed();
}

/// Clears all results and returns to the initial state.
class SpecialistSearchCleared extends SpecialistSearchEvent {
  const SpecialistSearchCleared();
}
