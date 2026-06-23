import 'package:equatable/equatable.dart';

/// A page of results plus the metadata required to drive infinite scrolling.
class PagedResult<T> extends Equatable {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  /// True when the last page has been reached and no further fetch is needed.
  bool get hasReachedMax => page * limit >= total || items.length < limit;

  /// Returns a new page that appends [more] to the existing [items], advancing
  /// to [nextPage]. Used by paginated BLoCs to accumulate results.
  PagedResult<T> appendPage(PagedResult<T> next) {
    return PagedResult<T>(
      items: [...items, ...next.items],
      total: next.total,
      page: next.page,
      limit: next.limit,
    );
  }

  @override
  List<Object?> get props => [items, total, page, limit];
}
