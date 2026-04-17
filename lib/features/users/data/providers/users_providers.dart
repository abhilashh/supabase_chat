import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../datasources/users_remote_datasource.dart';
import '../repositories/users_repository_impl.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/usecases/get_users_usecase.dart';

final usersRemoteDataSourceProvider = Provider<UsersRemoteDataSource>(
  (ref) => UsersRemoteDataSourceImpl(ref.watch(supabaseClientProvider)),
);

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepositoryImpl(ref.watch(usersRemoteDataSourceProvider)),
);

final getUsersUseCaseProvider = Provider<GetUsersUseCase>(
  (ref) => GetUsersUseCase(ref.watch(usersRepositoryProvider)),
);

final usersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final result =
      await ref.watch(getUsersUseCaseProvider).call(const NoParams());
  return result.fold(
    (failure) => throw failure.message,
    (users) => users,
  );
});
