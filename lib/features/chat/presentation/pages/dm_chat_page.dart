import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/dm_chat_notifier.dart';

class DmChatPage extends ConsumerStatefulWidget {
  final String roomId;
  final UserEntity otherUser;

  const DmChatPage({
    super.key,
    required this.roomId,
    required this.otherUser,
  });

  @override
  ConsumerState<DmChatPage> createState() => _DmChatPageState();
}

class _DmChatPageState extends ConsumerState<DmChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(UserEntity currentUser) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref.read(dmChatNotifierProvider(widget.roomId).notifier).sendMessage(
          content: text,
          senderId: currentUser.id,
          senderUsername: currentUser.username ?? currentUser.email,
        );
    _messageController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    ref.listen<AsyncValue<void>>(
        dmChatNotifierProvider(widget.roomId), (_, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()))),
      );
    });

    ref.listen(dmMessagesStreamProvider(widget.roomId), (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    final displayName =
        widget.otherUser.username ?? widget.otherUser.email;

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: Column(
        children: [
          Expanded(
            child: _DmMessageList(
              roomId: widget.roomId,
              scrollController: _scrollController,
              currentUserId: currentUser?.id,
            ),
          ),
          if (currentUser != null)
            _MessageInput(
              controller: _messageController,
              onSend: () => _sendMessage(currentUser),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DmMessageList extends ConsumerWidget {
  final String roomId;
  final ScrollController scrollController;
  final String? currentUserId;

  const _DmMessageList({
    required this.roomId,
    required this.scrollController,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(dmMessagesStreamProvider(roomId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(child: Text('No messages yet. Say hello!'));
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (_, i) => _MessageBubble(
            message: messages[i],
            isMe: messages[i].senderId == currentUserId,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
