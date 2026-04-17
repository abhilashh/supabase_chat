import 'package:subasechatapp/features/auth/data/models/user_model.dart';
import 'package:subasechatapp/features/chat/data/models/message_model.dart';

/// Reusable test fixtures — single source of truth for test data.

const tUserModel = UserModel(
  id: 'user-123',
  email: 'alice@example.com',
  username: 'alice',
);

final tFixedDate = DateTime.parse('2024-01-01T12:00:00.000Z');

MessageModel get tMessageModel => MessageModel(
      id: 'msg-001',
      senderId: 'user-123',
      senderUsername: 'alice',
      content: 'Hello world',
      createdAt: tFixedDate,
    );

List<MessageModel> get tMessageList => [tMessageModel];
