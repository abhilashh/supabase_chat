import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/users/presentation/pages/users_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/chat/presentation/pages/dm_chat_page.dart';

/// Bridges Riverpod auth state into a [ChangeNotifier] for GoRouter.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(ProviderContainer container) {
    _sub = container.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

GoRouter createRouter(ProviderContainer container) {
  final notifier = _AuthRouterNotifier(container);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = container.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isInitial = authState is AuthInitial;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Still checking session — stay put
      if (isInitial) return null;

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/users';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/chats', builder: (_, __) => const ChatPage()),
      GoRoute(path: '/users', builder: (_, __) => const UsersPage()),
      GoRoute(
        path: '/dm/:roomId',
        builder: (_, state) => DmChatPage(
          roomId: state.pathParameters['roomId']!,
          otherUser: state.extra as UserEntity,
        ),
      ),
    ],
  );
}
