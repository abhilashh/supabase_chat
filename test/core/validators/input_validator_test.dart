import 'package:flutter_test/flutter_test.dart';
import 'package:subasechatapp/core/validators/input_validator.dart';

void main() {
  // ---------------------------------------------------------------------------
  // email
  // ---------------------------------------------------------------------------
  group('InputValidator.email', () {
    test('returns right with trimmed value for a valid email', () {
      final result = InputValidator.email('  alice@example.com  ');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (v) => expect(v, 'alice@example.com'));
    });

    test('returns failure when empty', () {
      final result = InputValidator.email('');
      _expectFailure(result, 'Email is required');
    });

    test('returns failure when whitespace only', () {
      final result = InputValidator.email('   ');
      _expectFailure(result, 'Email is required');
    });

    test('returns failure when missing @', () {
      final result = InputValidator.email('notanemail.com');
      _expectFailure(result, 'Enter a valid email address');
    });

    test('returns failure when missing domain', () {
      final result = InputValidator.email('user@');
      _expectFailure(result, 'Enter a valid email address');
    });

    test('returns failure when missing TLD', () {
      final result = InputValidator.email('user@domain');
      _expectFailure(result, 'Enter a valid email address');
    });

    test('returns failure when longer than 254 chars', () {
      final long = '${'a' * 250}@b.co';
      final result = InputValidator.email(long);
      _expectFailure(result, 'Email address is too long');
    });

    test('accepts email with subdomain', () {
      expect(InputValidator.email('user@mail.example.co.uk').isRight(), isTrue);
    });

    test('accepts email with plus addressing', () {
      expect(InputValidator.email('user+tag@example.com').isRight(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // password
  // ---------------------------------------------------------------------------
  group('InputValidator.password', () {
    const valid = 'Password1!';

    test('returns right for a strong password', () {
      expect(InputValidator.password(valid).isRight(), isTrue);
    });

    test('returns failure when empty', () {
      _expectFailure(InputValidator.password(''), 'Password is required');
    });

    test('returns failure when shorter than 8 chars', () {
      final result = InputValidator.password('P1!aaaa');
      _expectFailure(result, contains('at least'));
    });

    test('returns failure when longer than 72 chars', () {
      final long = 'P1!${'a' * 70}';
      _expectFailure(InputValidator.password(long), 'Password is too long');
    });

    test('returns failure when no uppercase letter', () {
      _expectFailure(
        InputValidator.password('password1!'),
        contains('uppercase'),
      );
    });

    test('returns failure when no digit', () {
      _expectFailure(
        InputValidator.password('Password!'),
        contains('number'),
      );
    });

    test('returns failure when no special character', () {
      _expectFailure(
        InputValidator.password('Password1'),
        contains('special'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // username
  // ---------------------------------------------------------------------------
  group('InputValidator.username', () {
    test('returns right for a valid username', () {
      expect(InputValidator.username('alice99').isRight(), isTrue);
    });

    test('trims whitespace and validates', () {
      final result = InputValidator.username('  bob  ');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (v) => expect(v, 'bob'));
    });

    test('returns failure when empty', () {
      _expectFailure(InputValidator.username(''), 'Username is required');
    });

    test('returns failure when shorter than 3 chars', () {
      _expectFailure(InputValidator.username('ab'), contains('at least 3'));
    });

    test('returns failure when longer than 30 chars', () {
      _expectFailure(
        InputValidator.username('a' * 31),
        contains('at most 30'),
      );
    });

    test('returns failure when starts with underscore', () {
      _expectFailure(
        InputValidator.username('_alice'),
        contains('must not start or end'),
      );
    });

    test('returns failure when ends with underscore', () {
      _expectFailure(
        InputValidator.username('alice_'),
        contains('must not start or end'),
      );
    });

    test('returns failure when contains special characters', () {
      _expectFailure(
        InputValidator.username('alice!'),
        contains('letters, numbers, and underscores'),
      );
    });

    test('accepts username with internal underscore', () {
      expect(InputValidator.username('alice_bob').isRight(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // messageContent
  // ---------------------------------------------------------------------------
  group('InputValidator.messageContent', () {
    test('returns right for a normal message', () {
      expect(InputValidator.messageContent('Hello!').isRight(), isTrue);
    });

    test('trims whitespace before validation', () {
      final result = InputValidator.messageContent('  hi  ');
      expect(result.isRight(), isTrue);
      result.fold((_) {}, (v) => expect(v, 'hi'));
    });

    test('returns failure when empty', () {
      _expectFailure(
        InputValidator.messageContent(''),
        'Message cannot be empty',
      );
    });

    test('returns failure when whitespace only', () {
      _expectFailure(
        InputValidator.messageContent('   '),
        'Message cannot be empty',
      );
    });

    test('returns failure when longer than 2000 chars', () {
      _expectFailure(
        InputValidator.messageContent('a' * 2001),
        contains('at most 2000'),
      );
    });

    test('accepts a message of exactly 2000 chars', () {
      expect(
        InputValidator.messageContent('a' * 2000).isRight(),
        isTrue,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: assert the result is a Left with a message matching [matcher]
// ---------------------------------------------------------------------------
void _expectFailure(dynamic result, dynamic matcher) {
  expect(result.isLeft(), isTrue);
  result.fold(
    (f) => expect(f.message, matcher),
    (_) => fail('Expected a failure but got a success'),
  );
}
