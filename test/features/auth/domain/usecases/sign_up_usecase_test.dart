import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/core/errors/failures.dart';
import 'package:subasechatapp/core/validators/input_validator.dart';
import 'package:subasechatapp/features/auth/domain/usecases/sign_up_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late SignUpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = SignUpUseCase(mockRepo);
  });

  const tEmail = 'alice@example.com';
  const tPassword = 'Password1!';
  const tUsername = 'alice99';

  const tParams = SignUpParams(
    email: tEmail,
    password: tPassword,
    username: tUsername,
  );

  void stubSuccess() {
    when(() => mockRepo.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
        )).thenAnswer((_) async => right(tUserModel));
  }

  group('SignUpUseCase', () {
    test('returns user when all params are valid', () async {
      stubSuccess();

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      verify(() => mockRepo.signUpWithEmail(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          )).called(1);
    });

    test('returns AuthFailure when repository fails', () async {
      when(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          )).thenAnswer(
        (_) async => left(const AuthFailure('Email already in use')),
      );

      final result = await useCase(tParams);

      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    // --- Validation short-circuits ---

    test('ValidationFailure for invalid email — repo never called', () async {
      final result = await useCase(
        const SignUpParams(
          email: 'bad-email',
          password: tPassword,
          username: tUsername,
        ),
      );
      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          ));
    });

    test('ValidationFailure for weak password — repo never called', () async {
      final result = await useCase(
        const SignUpParams(
          email: tEmail,
          password: 'weak',
          username: tUsername,
        ),
      );
      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          ));
    });

    test('ValidationFailure for invalid username — repo never called', () async {
      final result = await useCase(
        const SignUpParams(
          email: tEmail,
          password: tPassword,
          username: '_bad_',
        ),
      );
      _expectValidationFailure(result);
      verifyNever(() => mockRepo.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
          ));
    });

    test('passes trimmed email and username to repository', () async {
      stubSuccess();

      await useCase(
        const SignUpParams(
          email: '  alice@example.com  ',
          password: tPassword,
          username: '  alice99  ',
        ),
      );

      verify(() => mockRepo.signUpWithEmail(
            email: 'alice@example.com',
            password: tPassword,
            username: 'alice99',
          )).called(1);
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
