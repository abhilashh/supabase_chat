import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/exceptions.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/features/chat/data/models/message_model.dart';
import 'package:subasechatapp/features/chat/data/repositories/chat_repository_impl.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockChatRemoteDataSource mockDataSource;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockChatRemoteDataSource();
    repository = ChatRepositoryImpl(mockDataSource);
  });

  const tContent = 'Hello world';
  const tSenderId = 'user-123';
  const tSenderUsername = 'alice';
  const tServerError = ServerException('Failed to load messages');

  // ---------------------------------------------------------------------------
  // getMessages
  // ---------------------------------------------------------------------------
  group('getMessages', () {
    test('returns Right(messages) when datasource succeeds', () async {
      when(() => mockDataSource.getMessages())
          .thenAnswer((_) async => tMessageList);

      final result = await repository.getMessages();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (messages) => expect(messages, tMessageList),
      );
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getMessages()).thenThrow(tServerError);

      final result = await repository.getMessages();

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, tServerError.message);
        },
        (_) => fail('Expected Left'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------
  group('sendMessage', () {
    test('returns Right(unit) when datasource succeeds', () async {
      when(() => mockDataSource.sendMessage(
            content: tContent,
            senderId: tSenderId,
            senderUsername: tSenderUsername,
          )).thenAnswer((_) async {});

      final result = await repository.sendMessage(
        content: tContent,
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      );

      expect(result, right(unit));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).thenThrow(const ServerException('Failed to send message'));

      final result = await repository.sendMessage(
        content: tContent,
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Expected Left'));
    });
  });

  // ---------------------------------------------------------------------------
  // subscribeToMessages
  // ---------------------------------------------------------------------------
  group('subscribeToMessages', () {
    test('returns stream from datasource', () {
      final tStream = Stream.value(tMessageList);
      when(() => mockDataSource.subscribeToMessages()).thenAnswer((_) => tStream);

      final result = repository.subscribeToMessages();

      expect(result, emits(tMessageList));
    });

    test('propagates stream errors', () {
      when(() => mockDataSource.subscribeToMessages()).thenAnswer(
        (_) => Stream<List<MessageModel>>.error(Exception('stream error')),
      );

      final result = repository.subscribeToMessages();

      expect(result, emitsError(isA<Exception>()));
    });
  });
}
