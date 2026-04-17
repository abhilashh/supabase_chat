import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/core/validators/input_validator.dart';
import 'package:subasechatapp/features/chat/domain/usecases/send_message_usecase.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockChatRepository mockRepo;
  late SendMessageUseCase useCase;

  setUp(() {
    mockRepo = MockChatRepository();
    useCase = SendMessageUseCase(mockRepo);
  });

  const tSenderId = 'user-123';
  const tSenderUsername = 'alice';

  group('SendMessageUseCase', () {
    test('sends trimmed content when valid', () async {
      when(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).thenAnswer((_) async => right(unit));

      final result = await useCase(const SendMessageParams(
        content: '  Hello!  ',
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      ));

      expect(result.isRight(), isTrue);
      // Repo should receive the trimmed value
      verify(() => mockRepo.sendMessage(
            content: 'Hello!',
            senderId: tSenderId,
            senderUsername: tSenderUsername,
          )).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).thenAnswer((_) async => left(const ServerFailure('Failed to send message')));

      final result = await useCase(const SendMessageParams(
        content: 'Hello',
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      ));

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('returns ValidationFailure for empty content — repo never called', () async {
      final result = await useCase(const SendMessageParams(
        content: '',
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      ));

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
      verifyNever(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          ));
    });

    test('returns ValidationFailure for whitespace-only content', () async {
      final result = await useCase(const SendMessageParams(
        content: '    ',
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      ));

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });

    test('returns ValidationFailure for content exceeding 2000 chars', () async {
      final result = await useCase(SendMessageParams(
        content: 'a' * 2001,
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      ));

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
      verifyNever(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          ));
    });
  });
}
