import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/video_repository.dart';

/// Marks the appointment's live session as started on the backend.
class StartVideoSession extends UseCase<void, String> {
  StartVideoSession(this._repository);

  final VideoRepository _repository;

  @override
  ResultVoid call(String params) => _repository.startSession(params);
}
