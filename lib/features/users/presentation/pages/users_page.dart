import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../chat/data/providers/dm_providers.dart';
import '../../data/providers/users_providers.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) {
          final others =
              currentUserId != null
                  ? users.where((u) => u.id != currentUserId).toList()
                  : users;

          if (others.isEmpty) {
            return const Center(child: Text('No other users yet.'));
          }
          return ListView.builder(
            itemCount: others.length,
            itemBuilder: (_, i) => _UserTile(user: others[i]),
          );
        },
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  final UserEntity user;
  const _UserTile({required this.user});

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _loading = false;

  Future<void> _openChat() async {
    setState(() => _loading = true);
    final result = await ref
        .read(getOrCreateRoomUseCaseProvider)
        .call(widget.user.id);
    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
      (roomId) => context.push('/dm/$roomId', extra: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.username ?? widget.user.email;
    final initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.user.avatarUrl != null
            ? NetworkImage(widget.user.avatarUrl!)
            : null,
        child: widget.user.avatarUrl == null ? Text(initials) : null,
      ),
      title: Text(widget.user.username ?? widget.user.email),
      subtitle: widget.user.username != null ? Text(widget.user.email) : null,
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _loading ? null : _openChat,
    );
  }
}
