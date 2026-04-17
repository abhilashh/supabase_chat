import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';

abstract interface class DmRemoteDataSource {
  /// Returns the room ID for a DM between the current user and [otherUserId],
  /// creating one atomically if it does not exist.
  Future<String> getOrCreateRoom(String otherUserId);

  Future<void> sendDmMessage({
    required String roomId,
    required String content,
    required String senderId,
    required String senderUsername,
  });

  Stream<List<MessageModel>> subscribeToDmMessages(String roomId);
}

class DmRemoteDataSourceImpl implements DmRemoteDataSource {
  final SupabaseClient _supabase;
  const DmRemoteDataSourceImpl(this._supabase);

  @override
  Future<String> getOrCreateRoom(String otherUserId) async {
    try {
      final roomId = await _supabase
          .rpc('get_or_create_dm_room', params: {'other_user_id': otherUserId});
      return roomId as String;
    } catch (_) {
      throw const ServerException('Failed to open conversation');
    }
  }

  @override
  Future<void> sendDmMessage({
    required String roomId,
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.directMessagesTable).insert({
        'room_id': roomId,
        'content': content,
        'sender_id': senderId,
        'sender_username': senderUsername,
      });
    } catch (_) {
      throw const ServerException('Failed to send message');
    }
  }

  @override
  Stream<List<MessageModel>> subscribeToDmMessages(String roomId) {
    return _supabase
        .from(SupabaseConstants.directMessagesTable)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((data) => data.map((json) => MessageModel.fromJson(json)).toList());
  }
}
