import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/users_repository.dart';

class GetUsersUseCase implements UseCase<List<UserEntity>, NoParams> {
  final UsersRepository _repository;
  const GetUsersUseCase(this._repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) =>
      _repository.getUsers();
}
