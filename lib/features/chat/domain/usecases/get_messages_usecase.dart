import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase implements UseCase<List<MessageEntity>, NoParams> {
  final ChatRepository _repository;
  const GetMessagesUseCase(this._repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(NoParams params) {
    return _repository.getMessages();
  }
}
