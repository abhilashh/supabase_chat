import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/chat_providers.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/send_message_usecase.dart';

// ---------------------------------------------------------------------------
// Realtime stream provider — auto-cancels when widget disposes
// ---------------------------------------------------------------------------

final messagesStreamProvider = StreamProvider<List<MessageEntity>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.subscribeToMessages();
});

// ---------------------------------------------------------------------------
// Notifier for send actions — with client-side rate limiting
// ---------------------------------------------------------------------------

/// Maximum number of messages a user can send per [_rateLimitWindow].
const _maxMessagesPerWindow = 5;
const _rateLimitWindow = Duration(seconds: 10);

class ChatNotifier extends Notifier<AsyncValue<void>> {
  late final SendMessageUseCase _sendMessage;

  // Timestamps of recent sends for rate limiting
  final List<DateTime> _sendTimestamps = [];

  @override
  AsyncValue<void> build() {
    _sendMessage = SendMessageUseCase(ref.read(chatRepositoryProvider));
    return const AsyncData(null);
  }

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    // --- Rate limit check ---
    final now = DateTime.now();
    _sendTimestamps.removeWhere(
      (t) => now.difference(t) > _rateLimitWindow,
    );
    if (_sendTimestamps.length >= _maxMessagesPerWindow) {
      state = AsyncError(
        'You are sending messages too quickly. Please slow down.',
        StackTrace.current,
      );
      return;
    }
    _sendTimestamps.add(now);

    state = const AsyncLoading();
    final result = await _sendMessage(SendMessageParams(
      content: content,
      senderId: senderId,
      senderUsername: senderUsername,
    ));
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, AsyncValue<void>>(ChatNotifier.new);
