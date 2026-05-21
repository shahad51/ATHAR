import 'package:flutter_test/flutter_test.dart';
import 'package:athar_app/core/utils/validators.dart';

void main() {
  group('Validators.validateRequired', () {
    test('returns error for null', () {
      expect(Validators.validateRequired(null, 'Field'), 'Field is required');
    });
    test('returns error for empty string', () {
      expect(Validators.validateRequired('', 'Field'), 'Field is required');
    });
    test('returns error for whitespace only', () {
      expect(Validators.validateRequired('   ', 'Field'), 'Field is required');
    });
    test('returns null for valid value', () {
      expect(Validators.validateRequired('value', 'Field'), isNull);
    });
  });

  group('Validators.validateMobile', () {
    test('returns error for null', () {
      expect(Validators.validateMobile(null), 'Mobile number is required');
    });
    test('returns error for empty', () {
      expect(Validators.validateMobile(''), 'Mobile number is required');
    });
    test('returns error for too short', () {
      expect(Validators.validateMobile('123'), 'Please enter a valid mobile number');
    });
    test('returns error for too long', () {
      expect(Validators.validateMobile('1234567890123456'), 'Please enter a valid mobile number');
    });
    test('returns error for letters', () {
      expect(Validators.validateMobile('abc123'), 'Please enter a valid mobile number');
    });
    test('accepts valid mobile with +', () {
      expect(Validators.validateMobile('+966501234567'), isNull);
    });
    test('accepts valid mobile without +', () {
      expect(Validators.validateMobile('966501234567'), isNull);
    });
    test('accepts valid mobile with spaces/dashes', () {
      expect(Validators.validateMobile('+966 50 123 4567'), isNull);
      expect(Validators.validateMobile('050-123-4567'), isNull);
    });
  });

  group('Validators.validateUsername', () {
    test('returns error for null', () {
      expect(Validators.validateUsername(null), 'Username is required');
    });
    test('returns error for too short', () {
      expect(Validators.validateUsername('ab'), 'Username must be at least 3 characters');
    });
    test('returns error for special characters', () {
      expect(Validators.validateUsername('user@name'), 'Username can only contain letters, numbers, and underscores');
    });
    test('accepts valid username', () {
      expect(Validators.validateUsername('ahmed_ali_123'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error for null', () {
      expect(Validators.validatePassword(null), 'Password is required');
    });
    test('returns error for too short', () {
      expect(Validators.validatePassword('Short1'), 'Password must be at least 8 characters');
    });
    test('returns error for no uppercase', () {
      expect(Validators.validatePassword('lowercase123'), 'Password must contain at least one uppercase letter');
    });
    test('returns error for no number', () {
      expect(Validators.validatePassword('NoNumbersHere'), 'Password must contain at least one number');
    });
    test('accepts valid password', () {
      expect(Validators.validatePassword('StrongPass123'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns error for null', () {
      expect(Validators.validateConfirmPassword(null, 'pass'), 'Please confirm your password');
    });
    test('returns error for mismatch', () {
      expect(Validators.validateConfirmPassword('wrong', 'password'), 'Passwords do not match');
    });
    test('accepts matching password', () {
      expect(Validators.validateConfirmPassword('password', 'password'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('returns error for null', () {
      expect(Validators.validateName(null, 'First Name'), 'First Name is required');
    });
    test('returns error for too short', () {
      expect(Validators.validateName('A', 'Name'), 'Name must be at least 2 characters');
    });
    test('accepts valid name', () {
      expect(Validators.validateName('Ahmed', 'Name'), isNull);
    });
  });

  group('Validators.isValidPassword', () {
    test('returns false for weak password', () {
      expect(Validators.isValidPassword('weak'), false);
    });
    test('returns true for strong password', () {
      expect(Validators.isValidPassword('StrongPass123'), true);
    });
    test('returns false for missing number', () {
      expect(Validators.isValidPassword('NoNumberHere'), false);
    });
    test('returns false for missing uppercase', () {
      expect(Validators.isValidPassword('nonumber123'), false);
    });
  });
}
