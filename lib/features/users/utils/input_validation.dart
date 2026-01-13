// Input Validation Utility for User Settings
// Provides validation methods for user profile and preference inputs

class InputValidation {
  // Validate display name
  static ValidationResult validateDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return ValidationResult(false, 'Display name cannot be empty');
    }

    if (displayName.length < 2) {
      return ValidationResult(
        false,
        'Display name must be at least 2 characters',
      );
    }

    if (displayName.length > 50) {
      return ValidationResult(
        false,
        'Display name must be less than 50 characters',
      );
    }

    // Check for invalid characters (allow letters, numbers, spaces, hyphens, underscores, and periods)
    final RegExp nameRegExp = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');
    if (!nameRegExp.hasMatch(displayName)) {
      return ValidationResult(
        false,
        'Display name contains invalid characters',
      );
    }

    return ValidationResult(true);
  }

  // Validate bio
  static ValidationResult validateBio(String bio) {
    if (bio.isEmpty) {
      return ValidationResult(true); // Bio is optional
    }

    if (bio.length > 200) {
      return ValidationResult(false, 'Bio must be less than 200 characters');
    }

    // Check for inappropriate content (basic check)
    final String lowerBio = bio.toLowerCase();
    final List<String> forbiddenWords = [
      'fuck', 'shit', 'damn', 'hell', // Add more as needed
    ];

    for (final word in forbiddenWords) {
      if (lowerBio.contains(word)) {
        return ValidationResult(false, 'Bio contains inappropriate content');
      }
    }

    return ValidationResult(true);
  }

  // Validate daily goal
  static ValidationResult validateDailyGoal(String dailyGoal) {
    if (dailyGoal.isEmpty) {
      return ValidationResult(false, 'Daily goal cannot be empty');
    }

    final int? goal = int.tryParse(dailyGoal);
    if (goal == null) {
      return ValidationResult(false, 'Daily goal must be a number');
    }

    if (goal < 5) {
      return ValidationResult(false, 'Daily goal must be at least 5 minutes');
    }

    if (goal > 480) {
      return ValidationResult(
        false,
        'Daily goal cannot exceed 480 minutes (8 hours)',
      );
    }

    return ValidationResult(true);
  }

  // Validate email (basic validation)
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(false, 'Email cannot be empty');
    }

    // Basic email regex pattern
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(false, 'Please enter a valid email address');
    }

    if (email.length > 254) {
      return ValidationResult(false, 'Email is too long');
    }

    return ValidationResult(true);
  }

  // Validate password
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Password cannot be empty');
    }

    if (password.length < 6) {
      return ValidationResult(false, 'Password must be at least 6 characters');
    }

    if (password.length > 128) {
      return ValidationResult(false, 'Password is too long');
    }

    // Check for at least one letter and one number
    final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final bool hasNumber = RegExp(r'[0-9]').hasMatch(password);

    if (!hasLetter || !hasNumber) {
      return ValidationResult(
        false,
        'Password must contain both letters and numbers',
      );
    }

    return ValidationResult(true);
  }
}

// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult(this.isValid, [this.errorMessage]);

  @override
  String toString() {
    return 'ValidationResult{isValid: $isValid, errorMessage: $errorMessage}';
  }
}
