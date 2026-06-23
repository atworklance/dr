part of 'specialist_search_bloc.dart';

enum SearchStatus { initial, loading, loadingMore, success, failure }

class SpecialistSearchState extends Equatable {
  const SpecialistSearchState({
    this.status = SearchStatus.initial,
    this.filter = const SearchFilter(),
    this.results,
    this.failure,
  });

  final SearchStatus status;
  final SearchFilter filter;
  final PagedResult<Specialist>? results;
  final Failure? failure;

  List<Specialist> get specialists => results?.items ?? const [];
  bool get hasReachedMax => results?.hasReachedMax ?? false;
  bool get isLoadingFirstPage => status == SearchStatus.loading;
  bool get isLoadingMore => status == SearchStatus.loadingMore;
  bool get isEmpty =>
      status == SearchStatus.success && (results?.items.isEmpty ?? true);

  SpecialistSearchState copyWith({
    SearchStatus? status,
    SearchFilter? filter,
    PagedResult<Specialist>? results,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SpecialistSearchState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      results: results ?? this.results,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, filter, results, failure];
}
