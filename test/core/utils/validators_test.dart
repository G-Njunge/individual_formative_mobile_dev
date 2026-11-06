import 'package:flutter_test/flutter_test.dart';
import 'package:individual_formative/core/utils/validators.dart';

void main() {
  group('campusEmail', () {
    const students = ['alustudent.com'];

    test('requires a value', () {
      expect(Validators.campusEmail(''), 'Campus email is required');
      expect(Validators.campusEmail('   '), 'Campus email is required');
    });

    test('rejects malformed addresses', () {
      expect(Validators.campusEmail('amani'), 'Enter a valid email address');
      expect(
        Validators.campusEmail('amani@alustudent'),
        'Enter a valid email address',
      );
    });

    test('enforces the allowed domain, ignoring case and spaces', () {
      expect(
        Validators.campusEmail(
          ' A.Mugisha@ALUstudent.com ',
          allowedDomains: students,
        ),
        isNull,
      );
      expect(
        Validators.campusEmail('a@gmail.com', allowedDomains: students),
        'Use your campus email (@alustudent.com)',
      );
    });

    test('skips the domain check when no domains are given', () {
      expect(Validators.campusEmail('a@gmail.com'), isNull);
    });
  });

  group('password', () {
    test('needs at least 8 characters', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('short'), 'Use at least 8 characters');
      expect(Validators.password('longenough'), isNull);
    });

    test('confirm must match', () {
      expect(
        Validators.confirmPassword('campus20', 'campus2026'),
        'Passwords do not match',
      );
      expect(Validators.confirmPassword('campus2026', 'campus2026'), isNull);
    });

    test('strength', () {
      expect(Validators.passwordStrength(''), PasswordStrength.none);
      expect(Validators.passwordStrength('abc'), PasswordStrength.weak);
      expect(Validators.passwordStrength('abcdefgh'), PasswordStrength.weak);
      expect(
        Validators.passwordStrength('campus2026'),
        PasswordStrength.medium,
      );
      expect(
        Validators.passwordStrength('Campus-2026!x'),
        PasswordStrength.strong,
      );
    });
  });

  group('report fields', () {
    test('title is required and bounded', () {
      expect(Validators.reportTitle(''), 'Title is required');
      expect(Validators.reportTitle('Tap'), 'Add a few more words');
      expect(Validators.reportTitle('Leaking tap in Block C'), isNull);
      expect(Validators.reportTitle('x' * 81), isNotNull);
    });

    test('description is required and at most 300 characters', () {
      expect(Validators.description(''), 'Description is required');
      expect(Validators.description('a' * 300), isNull);
      expect(Validators.description('a' * 301), isNotNull);
    });

    test('location is required', () {
      expect(Validators.location(''), 'Location is required');
      expect(Validators.location('Block C'), isNull);
    });

    test('staff ID format', () {
      expect(Validators.staffId('FAC-0231'), isNull);
      expect(Validators.staffId('fac0231'), isNull);
      expect(Validators.staffId('0231'), isNotNull);
    });
  });
}
