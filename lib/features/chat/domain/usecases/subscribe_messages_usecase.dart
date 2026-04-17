import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SubscribeMessagesUseCase {
  final ChatRepository _repository;
  const SubscribeMessagesUseCase(this._repository);

  Stream<List<MessageEntity>> call() {
    return _repository.subscribeToMessages();
  }
}
