/// Pure, reusable form-field validators returning `null` when valid or an error
/// message string when invalid (the contract `TextFormField.validator` expects).
abstract final class Validators {
  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{6,14}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final base = required(value, field: 'Email');
    if (base != null) return base;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!_e164.hasMatch(value.trim())) {
      return 'Use international format, e.g. +14155552671.';
    }
    return null;
  }

  static String? positiveAmount(String? value, {String field = 'Amount'}) {
    final base = required(value, field: field);
    if (base != null) return base;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) return 'Enter a valid $field.';
    return null;
  }
}
