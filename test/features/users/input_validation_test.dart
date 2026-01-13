import 'package:flutter_test/flutter_test.dart';
import 'package:mil_hub/features/users/utils/input_validation.dart';

void main() {
  group('InputValidation', () {
    group('validateDisplayName', () {
      test('should return valid for valid display name', () {
        final result = InputValidation.validateDisplayName('John Doe');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return invalid for empty display name', () {
        final result = InputValidation.validateDisplayName('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Display name cannot be empty');
      });

      test('should return invalid for display name too short', () {
        final result = InputValidation.validateDisplayName('J');
        expect(result.isValid, false);
        expect(
          result.errorMessage,
          'Display name must be at least 2 characters',
        );
      });

      test('should return invalid for display name too long', () {
        final longName = 'A' * 51; // 51 characters
        final result = InputValidation.validateDisplayName(longName);
        expect(result.isValid, false);
        expect(
          result.errorMessage,
          'Display name must be less than 50 characters',
        );
      });

      test(
        'should return invalid for display name with invalid characters',
        () {
          final result = InputValidation.validateDisplayName('John@Doe');
          expect(result.isValid, false);
          expect(
            result.errorMessage,
            'Display name contains invalid characters',
          );
        },
      );

      test(
        'should return valid for display name with valid special characters',
        () {
          final result = InputValidation.validateDisplayName('John-Doe_Jr.');
          expect(result.isValid, true);
          expect(result.errorMessage, null);
        },
      );
    });

    group('validateBio', () {
      test('should return valid for valid bio', () {
        final result = InputValidation.validateBio('This is my bio');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return valid for empty bio', () {
        final result = InputValidation.validateBio('');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return invalid for bio too long', () {
        final longBio = 'A' * 201; // 201 characters
        final result = InputValidation.validateBio(longBio);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Bio must be less than 200 characters');
      });

      test('should return invalid for bio with inappropriate content', () {
        final result = InputValidation.validateBio('This is a fuck bio');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Bio contains inappropriate content');
      });
    });

    group('validateDailyGoal', () {
      test('should return valid for valid daily goal', () {
        final result = InputValidation.validateDailyGoal('30');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return invalid for empty daily goal', () {
        final result = InputValidation.validateDailyGoal('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Daily goal cannot be empty');
      });

      test('should return invalid for non-numeric daily goal', () {
        final result = InputValidation.validateDailyGoal('abc');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Daily goal must be a number');
      });

      test('should return invalid for daily goal too small', () {
        final result = InputValidation.validateDailyGoal('4');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Daily goal must be at least 5 minutes');
      });

      test('should return invalid for daily goal too large', () {
        final result = InputValidation.validateDailyGoal('481');
        expect(result.isValid, false);
        expect(
          result.errorMessage,
          'Daily goal cannot exceed 480 minutes (8 hours)',
        );
      });
    });

    group('validateEmail', () {
      test('should return valid for valid email', () {
        final result = InputValidation.validateEmail('test@example.com');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return invalid for empty email', () {
        final result = InputValidation.validateEmail('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Email cannot be empty');
      });

      test('should return invalid for invalid email format', () {
        final result = InputValidation.validateEmail('invalid-email');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Please enter a valid email address');
      });
    });

    group('validatePassword', () {
      test('should return valid for valid password', () {
        final result = InputValidation.validatePassword('password123');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return invalid for empty password', () {
        final result = InputValidation.validatePassword('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Password cannot be empty');
      });

      test('should return invalid for password too short', () {
        final result = InputValidation.validatePassword('pass');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Password must be at least 6 characters');
      });

      test('should return invalid for password without letters', () {
        final result = InputValidation.validatePassword('123456');
        expect(result.isValid, false);
        expect(
          result.errorMessage,
          'Password must contain both letters and numbers',
        );
      });

      test('should return invalid for password without numbers', () {
        final result = InputValidation.validatePassword('password');
        expect(result.isValid, false);
        expect(
          result.errorMessage,
          'Password must contain both letters and numbers',
        );
      });
    });
  });
}
