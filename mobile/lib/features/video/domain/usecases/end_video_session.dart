import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/video_repository.dart';

/// Marks the appointment's live session as ended on the backend.
class EndVideoSession extends UseCase<void, String> {
  EndVideoSession(this._repository);

  final VideoRepository _repository;

  @override
  ResultVoid call(String params) => _repository.endSession(params);
}
