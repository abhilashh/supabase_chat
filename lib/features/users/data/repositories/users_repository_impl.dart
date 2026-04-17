import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource _remoteDataSource;
  const UsersRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers() async {
    try {
      final users = await _remoteDataSource.getUsers();
      return right(users);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }
}
