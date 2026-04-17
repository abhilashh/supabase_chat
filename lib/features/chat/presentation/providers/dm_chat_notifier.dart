import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/dm_providers.dart';
import '../../domain/entities/message_entity.dart';

// ---------------------------------------------------------------------------
// Realtime DM stream — scoped to a room, auto-cancels on dispose
// ---------------------------------------------------------------------------

final dmMessagesStreamProvider =
    StreamProvider.family<List<MessageEntity>, String>((ref, roomId) {
  final repo = ref.watch(dmRepositoryProvider);
  return repo.subscribeToDmMessages(roomId);
});

// ---------------------------------------------------------------------------
// Notifier for DM send actions
// ---------------------------------------------------------------------------

const _dmMaxMessagesPerWindow = 5;
const _dmRateLimitWindow = Duration(seconds: 10);

class DmChatNotifier extends FamilyNotifier<AsyncValue<void>, String> {
  final List<DateTime> _sendTimestamps = [];

  @override
  AsyncValue<void> build(String roomId) => const AsyncData(null);

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    final now = DateTime.now();
    _sendTimestamps.removeWhere((t) => now.difference(t) > _dmRateLimitWindow);
    if (_sendTimestamps.length >= _dmMaxMessagesPerWindow) {
      state = AsyncError(
        'You are sending messages too quickly. Please slow down.',
        StackTrace.current,
      );
      return;
    }
    _sendTimestamps.add(now);

    state = const AsyncLoading();
    final result = await ref.read(dmRepositoryProvider).sendDmMessage(
          roomId: arg,
          content: content,
          senderId: senderId,
          senderUsername: senderUsername,
        );
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

final dmChatNotifierProvider =
    NotifierProvider.family<DmChatNotifier, AsyncValue<void>, String>(
        DmChatNotifier.new);
