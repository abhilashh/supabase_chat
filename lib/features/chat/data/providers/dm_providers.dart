import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../datasources/dm_remote_datasource.dart';
import '../repositories/dm_repository_impl.dart';
import '../../domain/repositories/dm_repository.dart';
import '../../domain/usecases/get_or_create_room_usecase.dart';

final dmRemoteDataSourceProvider = Provider<DmRemoteDataSource>(
  (ref) => DmRemoteDataSourceImpl(ref.watch(supabaseClientProvider)),
);

final dmRepositoryProvider = Provider<DmRepository>(
  (ref) => DmRepositoryImpl(ref.watch(dmRemoteDataSourceProvider)),
);

final getOrCreateRoomUseCaseProvider = Provider<GetOrCreateRoomUseCase>(
  (ref) => GetOrCreateRoomUseCase(ref.watch(dmRepositoryProvider)),
);
