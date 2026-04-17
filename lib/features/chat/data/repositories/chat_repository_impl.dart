import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  const ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages() async {
    try {
      final messages = await _remoteDataSource.getMessages();
      return right(messages);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    try {
      await _remoteDataSource.sendMessage(
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
  Stream<List<MessageEntity>> subscribeToMessages() {
    return _remoteDataSource.subscribeToMessages();
  }
}
