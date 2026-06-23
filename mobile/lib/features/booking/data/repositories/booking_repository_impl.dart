import '../../../../core/entities/paged_result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/specialist.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

/// Implements [BookingRepository] over the remote data source, translating
/// data-layer exceptions into domain [Failure]s and short-circuiting offline.
class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required BookingRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  final BookingRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<PagedResult<Specialist>> searchSpecialists(SearchFilter filter) {
    return guardRemote(_networkInfo, () => _remote.searchSpecialists(filter));
  }

  @override
  ResultFuture<Specialist> getSpecialistById(String id) {
    return guardRemote(_networkInfo, () => _remote.getSpecialistById(id));
  }

  @override
  ResultFuture<Appointment> bookAppointment(BookingRequest request) {
    return guardRemote(_networkInfo, () => _remote.bookAppointment(request));
  }

  @override
  ResultFuture<Appointment> payForAppointment({
    required String appointmentId,
    required String paymentReference,
  }) {
    return guardRemote(
      _networkInfo,
      () => _remote.payForAppointment(
        appointmentId: appointmentId,
        paymentReference: paymentReference,
      ),
    );
  }
}
