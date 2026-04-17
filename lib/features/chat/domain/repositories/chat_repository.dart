import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';

abstract interface class ChatRepository {
  Future<Either<Failure, List<MessageEntity>>> getMessages();

  Future<Either<Failure, Unit>> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  });

  Stream<List<MessageEntity>> subscribeToMessages();
}
