import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/features/auth/data/providers/auth_providers.dart';
import 'package:subasechatapp/features/auth/presentation/providers/auth_notifier.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    // Every test needs getCurrentUser stubbed — build() calls it on first read.
    when(() => mockRepo.getCurrentUser())
        .thenAnswer((_) async => right(null));
  });

  /// Creates a container, eagerly reads the provider to trigger build(),
  /// then waits for the async _checkCurrentUser() side-effect to settle.
  Future<ProviderContainer> makeSettledContainer() async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    addTearDown(container.dispose);
    // Trigger build() so _checkCurrentUser() starts.
    container.read(authNotifierProvider);
    // Flush microtasks so _checkCurrentUser() completes before the test acts.
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  // ---------------------------------------------------------------------------

  group('AuthNotifier — initial state', () {
    test('starts as AuthInitial synchronously, then resolves to AuthUnauthenticated', () async {
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      // Immediately after first read → AuthInitial
      expect(container.read(authNotifierProvider), isA<AuthInitial>());

      // After async session check settles → AuthUnauthenticated
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });

    test('resolves to AuthAuthenticated when a session exists', () async {
      when(() => mockRepo.getCurrentUser())
          .thenAnswer((_) async => right(tUserModel));

      final container = await makeSettledContainer();

      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      final state = container.read(authNotifierProvider) as AuthAuthenticated;
      expect(state.user, tUserModel);
    });
  });

  // ---------------------------------------------------------------------------

  group('signIn', () {
    test('transitions Loading → Authenticated on success', () async {
      when(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => right(tUserModel));

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'alice@example.com', password: 'Password1!');

      expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
      expect((states.last as AuthAuthenticated).user, tUserModel);
    });

    test('transitions Loading → AuthError on failure', () async {
      when(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => left(const AuthFailure('Invalid email or password')),
      );

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'alice@example.com', password: 'Password1!');

      expect(states, [isA<AuthLoading>(), isA<AuthError>()]);
      expect((states.last as AuthError).message, 'Invalid email or password');
    });
  });

  // ---------------------------------------------------------------------------

  group('signUp', () {
    test('transitions Loading → Authenticated on success', () async {
      when(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          )).thenAnswer((_) async => right(tUserModel));

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container.read(authNotifierProvider.notifier).signUp(
            email: 'alice@example.com',
            password: 'Password1!',
            username: 'alice99',
          );

      expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
    });

    test('transitions Loading → AuthError on failure', () async {
      when(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          )).thenAnswer(
        (_) async => left(const AuthFailure('Email already in use')),
      );

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container.read(authNotifierProvider.notifier).signUp(
            email: 'alice@example.com',
            password: 'Password1!',
            username: 'alice99',
          );

      expect(states, [isA<AuthLoading>(), isA<AuthError>()]);
      expect((states.last as AuthError).message, 'Email already in use');
    });
  });

  // ---------------------------------------------------------------------------

  group('signOut', () {
    test('transitions Loading → AuthUnauthenticated on success', () async {
      when(() => mockRepo.signOut())
          .thenAnswer((_) async => right(unit));

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container.read(authNotifierProvider.notifier).signOut();

      expect(states, [isA<AuthLoading>(), isA<AuthUnauthenticated>()]);
    });

    test('transitions Loading → AuthError when signOut fails', () async {
      when(() => mockRepo.signOut()).thenAnswer(
        (_) async => left(const AuthFailure('Sign out failed')),
      );

      final container = await makeSettledContainer();

      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, s) => states.add(s));

      await container.read(authNotifierProvider.notifier).signOut();

      expect(states, [isA<AuthLoading>(), isA<AuthError>()]);
    });
  });
}
