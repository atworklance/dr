import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entities/paged_result.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/search_filter.dart';
import '../../../domain/entities/specialist.dart';
import '../../../domain/usecases/search_specialists.dart';

part 'specialist_search_event.dart';
part 'specialist_search_state.dart';

/// Drives the specialist directory: initial search, paginated "load more",
/// refresh, and clear. Accumulates pages so the UI can render an infinite list.
class SpecialistSearchBloc
    extends Bloc<SpecialistSearchEvent, SpecialistSearchState> {
  SpecialistSearchBloc(this._searchSpecialists)
      : super(const SpecialistSearchState()) {
    on<SpecialistSearchRequested>(_onRequested);
    on<SpecialistSearchMoreRequested>(_onMoreRequested);
    on<SpecialistSearchRefreshed>(_onRefreshed);
    on<SpecialistSearchCleared>(_onCleared);
  }

  final SearchSpecialists _searchSpecialists;

  Future<void> _runFreshSearch(
    SearchFilter filter,
    Emitter<SpecialistSearchState> emit,
  ) async {
    final firstPage = filter.firstPage();
    emit(state.copyWith(
      status: SearchStatus.loading,
      filter: firstPage,
      clearFailure: true,
    ));

    final result = await _searchSpecialists(firstPage);
    result.fold(
      (failure) => emit(state.copyWith(status: SearchStatus.failure, failure: failure)),
      (page) => emit(state.copyWith(status: SearchStatus.success, results: page)),
    );
  }

  Future<void> _onRequested(
    SpecialistSearchRequested event,
    Emitter<SpecialistSearchState> emit,
  ) =>
      _runFreshSearch(event.filter, emit);

  Future<void> _onRefreshed(
    SpecialistSearchRefreshed event,
    Emitter<SpecialistSearchState> emit,
  ) =>
      _runFreshSearch(state.filter, emit);

  Future<void> _onMoreRequested(
    SpecialistSearchMoreRequested event,
    Emitter<SpecialistSearchState> emit,
  ) async {
    final current = state.results;
    if (current == null ||
        current.hasReachedMax ||
        state.status == SearchStatus.loadingMore) {
      return;
    }

    final nextFilter = state.filter.copyWith(page: current.page + 1);
    emit(state.copyWith(status: SearchStatus.loadingMore, filter: nextFilter));

    final result = await _searchSpecialists(nextFilter);
    result.fold(
      (failure) => emit(state.copyWith(status: SearchStatus.failure, failure: failure)),
      (page) => emit(state.copyWith(
        status: SearchStatus.success,
        results: current.appendPage(page),
      )),
    );
  }

  void _onCleared(
    SpecialistSearchCleared event,
    Emitter<SpecialistSearchState> emit,
  ) {
    emit(const SpecialistSearchState());
  }
}
