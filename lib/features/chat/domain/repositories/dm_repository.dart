import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';

abstract interface class DmRepository {
  Future<Either<Failure, String>> getOrCreateRoom(String otherUserId);

  Future<Either<Failure, Unit>> sendDmMessage({
    required String roomId,
    required String content,
    required String senderId,
    required String senderUsername,
  });

  Stream<List<MessageEntity>> subscribeToDmMessages(String roomId);
}
