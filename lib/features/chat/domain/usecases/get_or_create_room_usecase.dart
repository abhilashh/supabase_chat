import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/dm_repository.dart';

class GetOrCreateRoomUseCase implements UseCase<String, String> {
  final DmRepository _repository;
  const GetOrCreateRoomUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(String otherUserId) =>
      _repository.getOrCreateRoom(otherUserId);
}
