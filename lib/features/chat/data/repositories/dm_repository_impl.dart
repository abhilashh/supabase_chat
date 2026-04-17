import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/dm_repository.dart';
import '../datasources/dm_remote_datasource.dart';

class DmRepositoryImpl implements DmRepository {
  final DmRemoteDataSource _remoteDataSource;
  const DmRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, String>> getOrCreateRoom(String otherUserId) async {
    try {
      final roomId = await _remoteDataSource.getOrCreateRoom(otherUserId);
      return right(roomId);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendDmMessage({
    required String roomId,
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    try {
      await _remoteDataSource.sendDmMessage(
        roomId: roomId,
        content: content,
        senderId: senderId,
        senderUsername: senderUsername,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<MessageEntity>> subscribeToDmMessages(String roomId) {
    return _remoteDataSource.subscribeToDmMessages(roomId);
  }
}
