import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/validators/input_validator.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase implements UseCase<Unit, SendMessageParams> {
  final ChatRepository _repository;
  const SendMessageUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(SendMessageParams params) {
    return InputValidator.messageContent(params.content).fold(
      (failure) async => left(failure),
      (validContent) => _repository.sendMessage(
        content: validContent,
        senderId: params.senderId,
        senderUsername: params.senderUsername,
      ),
    );
  }
}

class SendMessageParams extends Equatable {
  final String content;
  final String senderId;
  final String senderUsername;

  const SendMessageParams({
    required this.content,
    required this.senderId,
    required this.senderUsername,
  });

  @override
  List<Object> get props => [content, senderId, senderUsername];
}
