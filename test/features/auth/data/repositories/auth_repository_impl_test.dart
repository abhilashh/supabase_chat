import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/exceptions.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  const tEmail = 'alice@example.com';
  const tPassword = 'Password1!';
  const tUsername = 'alice99';
  const tAuthError = AppAuthException('Invalid credentials');
  const tServerError = ServerException('Network error');

  // ---------------------------------------------------------------------------
  // signInWithEmail
  // ---------------------------------------------------------------------------
  group('signInWithEmail', () {
    test('returns Right(user) when datasource succeeds', () async {
      when(() => mockDataSource.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => tUserModel);

      final result = await repository.signInWithEmail(
        email: tEmail,
        password: tPassword,
      );

      expect(result, right(tUserModel));
    });

    test('returns Left(AuthFailure) when datasource throws AppAuthException', () async {
      when(() => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(tAuthError);

      final result = await repository.signInWithEmail(
        email: tEmail,
        password: tPassword,
      );

      result.fold(
        (f) {
          expect(f, isA<AuthFailure>());
          expect(f.message, tAuthError.message);
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) when datasource throws ServerException', () async {
      when(() => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(tServerError);

      final result = await repository.signInWithEmail(
        email: tEmail,
        password: tPassword,
      );

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // signUpWithEmail
  // ---------------------------------------------------------------------------
  group('signUpWithEmail', () {
    test('returns Right(user) when datasource succeeds', () async {
      when(() => mockDataSource.signUpWithEmail(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          )).thenAnswer((_) async => tUserModel);

      final result = await repository.signUpWithEmail(
        email: tEmail,
        password: tPassword,
        username: tUsername,
      );

      expect(result, right(tUserModel));
    });

    test('returns Left(AuthFailure) on AppAuthException', () async {
      when(() => mockDataSource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          )).thenThrow(tAuthError);

      final result = await repository.signUpWithEmail(
        email: tEmail,
        password: tPassword,
        username: tUsername,
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<AuthFailure>()), (_) => fail('Expected Left'));
    });
  });

  // ---------------------------------------------------------------------------
  // signOut
  // ---------------------------------------------------------------------------
  group('signOut', () {
    test('returns Right(unit) when datasource succeeds', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, right(unit));
    });

    test('returns Right(unit) even when datasource swallows the error', () async {
      // signOut in datasource swallows errors; repo should still return right
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getCurrentUser
  // ---------------------------------------------------------------------------
  group('getCurrentUser', () {
    test('returns Right(user) when a session exists', () async {
      when(() => mockDataSource.getCurrentUser())
          .thenAnswer((_) async => tUserModel);

      final result = await repository.getCurrentUser();

      expect(result, right(tUserModel));
    });

    test('returns Right(null) when no active session', () async {
      when(() => mockDataSource.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, right(null));
    });

    test('returns Left(AuthFailure) on AppAuthException', () async {
      when(() => mockDataSource.getCurrentUser()).thenThrow(tAuthError);

      final result = await repository.getCurrentUser();

      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
