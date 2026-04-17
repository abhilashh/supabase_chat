import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<MessageModel>> getMessages();

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  });

  Stream<List<MessageModel>> subscribeToMessages();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase;
  const ChatRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<MessageModel>> getMessages() async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.messagesTable)
          .select()
          .order('created_at');

      return (data as List)
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ServerException('Failed to load messages');
    }
  }

  @override
  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderUsername,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.messagesTable).insert({
        'content': content,
        'sender_id': senderId,
        'sender_username': senderUsername,
      });
    } catch (_) {
      throw const ServerException('Failed to send message');
    }
  }

  @override
  Stream<List<MessageModel>> subscribeToMessages() {
    return _supabase
        .from(SupabaseConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data
            .map((json) => MessageModel.fromJson(json))
            .toList());
  }
}
