import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract interface class UsersRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers();
}
