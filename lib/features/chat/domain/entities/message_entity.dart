import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, senderId, content, createdAt];
}
