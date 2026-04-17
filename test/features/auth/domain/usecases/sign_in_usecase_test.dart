import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/core/validators/input_validator.dart';
import 'package:subasechatapp/features/auth/domain/usecases/sign_in_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late SignInUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = SignInUseCase(mockRepo);
  });

  group('SignInUseCase', () {
    const tEmail = 'alice@example.com';
    const tPassword = 'Password1!';

    test('returns user on valid credentials', () async {
      when(() => mockRepo.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => right(tUserModel));

      final result = await useCase(
        const SignInParams(email: tEmail, password: tPassword),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (user) => expect(user, tUserModel),
      );
      verify(() => mockRepo.signInWithEmail(
            email: tEmail,
            password: tPassword,
          )).called(1);
    });

    test('returns AuthFailure when repository fails', () async {
      when(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => left(const AuthFailure('Invalid email or password')),
      );

      final result = await useCase(
        const SignInParams(email: tEmail, password: tPassword),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('returns ValidationFailure for invalid email — repo never called', () async {
      final result = await useCase(
        const SignInParams(email: 'not-an-email', password: tPassword),
      );

      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns ValidationFailure for empty email — repo never called', () async {
      final result = await useCase(
        const SignInParams(email: '', password: tPassword),
      );

      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns ValidationFailure for empty password — repo never called', () async {
      final result = await useCase(
        const SignInParams(email: tEmail, password: ''),
      );

      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  });
}

void _expectValidationFailure(dynamic result) {
  expect(result.isLeft(), isTrue);
  result.fold(
    (f) => expect(f, isA<ValidationFailure>()),
    (_) => fail('Expected ValidationFailure'),
  );
}
