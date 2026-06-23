import '../../../../core/entities/paged_result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/search_filter.dart';
import '../entities/specialist.dart';
import '../repositories/booking_repository.dart';

/// Searches the specialist directory with the supplied [SearchFilter].
class SearchSpecialists extends UseCase<PagedResult<Specialist>, SearchFilter> {
  SearchSpecialists(this._repository);

  final BookingRepository _repository;

  @override
  ResultFuture<PagedResult<Specialist>> call(SearchFilter params) =>
      _repository.searchSpecialists(params);
}
