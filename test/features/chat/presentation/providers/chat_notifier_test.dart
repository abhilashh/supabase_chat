import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/features/chat/data/providers/chat_providers.dart';
import 'package:subasechatapp/features/chat/domain/entities/message_entity.dart';
import 'package:subasechatapp/features/chat/presentation/providers/chat_notifier.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockChatRepository mockRepo;

  setUp(() {
    mockRepo = MockChatRepository();
    // messagesStreamProvider needs subscribeToMessages stubbed
    when(() => mockRepo.subscribeToMessages())
        .thenAnswer((_) => Stream.value(tMessageList));
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  const tSenderId = 'user-123';
  const tSenderUsername = 'alice';

  void stubSendSuccess() {
    when(() => mockRepo.sendMessage(
          content: any(named: 'content'),
          senderId: any(named: 'senderId'),
          senderUsername: any(named: 'senderUsername'),
        )).thenAnswer((_) async => right(unit));
  }

  // ---------------------------------------------------------------------------

  group('ChatNotifier — initial state', () {
    test('starts as AsyncData(null)', () {
      final container = makeContainer();
      expect(container.read(chatNotifierProvider), isA<AsyncData<void>>());
    });
  });

  // ---------------------------------------------------------------------------

  group('sendMessage', () {
    test('transitions to AsyncLoading then AsyncData on success', () async {
      stubSendSuccess();
      final container = makeContainer();

      final states = <AsyncValue<void>>[];
      container.listen(chatNotifierProvider, (_, s) => states.add(s));

      await container.read(chatNotifierProvider.notifier).sendMessage(
            content: 'Hello!',
            senderId: tSenderId,
            senderUsername: tSenderUsername,
          );

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('transitions to AsyncError on repository failure', () async {
      when(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).thenAnswer(
        (_) async => left(const ServerFailure('Failed to send message')),
      );

      final container = makeContainer();

      final states = <AsyncValue<void>>[];
      container.listen(chatNotifierProvider, (_, s) => states.add(s));

      await container.read(chatNotifierProvider.notifier).sendMessage(
            content: 'Hello!',
            senderId: tSenderId,
            senderUsername: tSenderUsername,
          );

      expect(states.last, isA<AsyncError<void>>());
      expect(
        (states.last as AsyncError<void>).error,
        'Failed to send message',
      );
    });

    test('returns AsyncError for empty content without calling repo', () async {
      final container = makeContainer();

      final states = <AsyncValue<void>>[];
      container.listen(chatNotifierProvider, (_, s) => states.add(s));

      await container.read(chatNotifierProvider.notifier).sendMessage(
            content: '',
            senderId: tSenderId,
            senderUsername: tSenderUsername,
          );

      // Validation failure — no Loading, straight to error
      expect(states.last, isA<AsyncError<void>>());
      verifyNever(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          ));
    });
  });

  // ---------------------------------------------------------------------------

  group('ChatNotifier — rate limiting', () {
    test('allows up to 5 messages within 10 seconds', () async {
      stubSendSuccess();
      final container = makeContainer();
      final notifier = container.read(chatNotifierProvider.notifier);

      for (var i = 0; i < 5; i++) {
        await notifier.sendMessage(
          content: 'msg $i',
          senderId: tSenderId,
          senderUsername: tSenderUsername,
        );
        expect(
          container.read(chatNotifierProvider),
          isA<AsyncData<void>>(),
          reason: 'message $i should succeed',
        );
      }

      verify(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).called(5);
    });

    test('blocks the 6th message and emits AsyncError', () async {
      stubSendSuccess();
      final container = makeContainer();
      final notifier = container.read(chatNotifierProvider.notifier);

      // Send 5 allowed messages
      for (var i = 0; i < 5; i++) {
        await notifier.sendMessage(
          content: 'msg $i',
          senderId: tSenderId,
          senderUsername: tSenderUsername,
        );
      }

      // 6th should be rate-limited
      await notifier.sendMessage(
        content: 'too fast',
        senderId: tSenderId,
        senderUsername: tSenderUsername,
      );

      final state = container.read(chatNotifierProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError<void>).error,
        contains('too quickly'),
      );

      // Repo should only have been called 5 times, not 6
      verify(() => mockRepo.sendMessage(
            content: any(named: 'content'),
            senderId: any(named: 'senderId'),
            senderUsername: any(named: 'senderUsername'),
          )).called(5);
    });
  });

  // ---------------------------------------------------------------------------

  group('messagesStreamProvider', () {
    test('emits message list from repository stream', () async {
      final container = makeContainer();

      final stream = container.read(messagesStreamProvider.future);
      final messages = await stream;

      expect(messages, tMessageList);
    });

    test('emits error state when stream errors', () async {
      when(() => mockRepo.subscribeToMessages()).thenAnswer(
        (_) => Stream<List<MessageEntity>>.error(Exception('realtime error')),
      );

      final container = makeContainer();

      // Await the StreamProvider's future — it completes (or errors) once the
      // stream emits its first event, guaranteeing the state has been updated.
      await container.read(messagesStreamProvider.future).catchError((_) => <MessageEntity>[]);

      final state = container.read(messagesStreamProvider);
      expect(state, isA<AsyncError<dynamic>>());
    });
  });
}
