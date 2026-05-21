class Validators {
  Validators._();

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    if (!v.trim().contains('@') || !v.trim().contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your phone number';
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number (min 10 digits)';
    return null;
  }

  static String? required(String? v, [String message = 'This field is required']) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  static String? jobTitle(String? v) {
    if (v == null || v.trim().length < 3) return 'Enter a descriptive title (min 3 characters)';
    return null;
  }

  static String? jobDescription(String? v) {
    if (v == null || v.trim().length < 10) return 'Please describe the job (min 10 characters)';
    return null;
  }

  static String? location(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a location';
    return null;
  }

  static String? budget(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter a valid budget amount';
    return null;
  }
}
