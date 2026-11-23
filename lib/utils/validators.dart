/// Form validators shared by the authentication screens.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please choose a username';
    if (text.length < 3) return 'At least 3 characters';
    if (text.length > 30) return 'Maximum 30 characters';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please enter a password';
    if (text.length < 6) return 'At least 6 characters';
    return null;
  }

  /// Returns a validator checking that the field equals [original()].
  static String? Function(String?) confirmation(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }
}
