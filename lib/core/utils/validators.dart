import '../config/app_config.dart';

enum PasswordStrength {
  none(0),
  weak(1),
  medium(2),
  strong(3);

  const PasswordStrength(this.bars);

  /// How many of the three meter bars are filled.
  final int bars;
}

/// What a new password must contain. Shown as a live checklist on Create
/// account, so people see what is missing while they type instead of being
/// stopped at the end. Keep in step with the password policy in the Firebase
/// console (Authentication > Settings > Password policy).
enum PasswordRequirement {
  length(
    'At least ${AppConfig.minPasswordLength} characters',
    'more characters',
  ),
  uppercase('An uppercase letter (A-Z)', 'an uppercase letter'),
  lowercase('A lowercase letter (a-z)', 'a lowercase letter'),
  number('A number (0-9)', 'a number'),
  symbol('A symbol, such as ! # or @', 'a symbol');

  const PasswordRequirement(this.label, this.missing);

  /// The checklist line.
  final String label;

  /// How the error message names it when it is missing.
  final String missing;

  bool isMetBy(String password) => switch (this) {
    length => password.length >= AppConfig.minPasswordLength,
    uppercase => RegExp('[A-Z]').hasMatch(password),
    lowercase => RegExp('[a-z]').hasMatch(password),
    number => RegExp(r'\d').hasMatch(password),
    symbol => RegExp('[^A-Za-z0-9]').hasMatch(password),
  };

  static List<PasswordRequirement> missingFrom(String password) => [
    for (final r in values)
      if (!r.isMetBy(password)) r,
  ];
}

/// Form validators. Each returns an error message, or null when the value is
/// valid, so they plug straight into `FormField.validator`.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@([^\s@]+\.[^\s@]+)$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? fullName(String? value) {
    final error = required(value, field: 'Your name');
    if (error != null) return error;
    if (value!.trim().length < 2) return 'Enter your full name';
    return null;
  }

  /// Checks the format and that the domain is one the campus allows for the
  /// chosen role. Pass `allowedDomains: null` to skip the domain check
  /// (sign in accepts both student and staff domains).
  static String? campusEmail(String? value, {List<String>? allowedDomains}) {
    final error = required(value, field: 'Campus email');
    if (error != null) return error;
    final match = _emailPattern.firstMatch(value!.trim().toLowerCase());
    if (match == null) return 'Enter a valid email address';
    if (allowedDomains != null && !allowedDomains.contains(match.group(1))) {
      return 'Use your campus email (@${allowedDomains.join(' or @')})';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    final missing = [
      for (final r in PasswordRequirement.missingFrom(value)) r.missing,
    ];
    if (missing.isEmpty) return null;
    if (missing.length == 1) return 'Add ${missing.single}';
    final last = missing.removeLast();
    return 'Add ${missing.join(', ')} and $last';
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? staffId(String? value) {
    final error = required(value, field: 'Staff ID');
    if (error != null) return error;
    if (!RegExp(r'^[A-Za-z]{2,5}-?\d{2,6}$').hasMatch(value!.trim())) {
      return 'Use the format on your staff card, e.g. FAC-0231';
    }
    return null;
  }

  static String? reportTitle(String? value) {
    final error = required(value, field: 'Title');
    if (error != null) return error;
    if (value!.trim().length < 5) return 'Add a few more words';
    if (value.trim().length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? description(String? value) {
    final error = required(value, field: 'Description');
    if (error != null) return error;
    if (value!.trim().length > AppConfig.maxDescriptionLength) {
      return 'Keep it under ${AppConfig.maxDescriptionLength} characters';
    }
    return null;
  }

  static String? location(String? value) => required(value, field: 'Location');

  /// Scores length and variety of characters. Anything under the minimum
  /// length is weak no matter what it contains.
  static PasswordStrength passwordStrength(String value) {
    if (value.isEmpty) return PasswordStrength.none;
    if (value.length < AppConfig.minPasswordLength) {
      return PasswordStrength.weak;
    }
    var score = 0;
    if (value.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (score >= 3) return PasswordStrength.strong;
    if (score >= 1) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }
}
