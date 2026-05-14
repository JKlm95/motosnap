/// Walidacja pól formularzy auth — bez zależności od Fluttera.
abstract final class AuthInputValidators {
  static String? emailError(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'Podaj adres e-mail.';
    }
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmed);
    if (!ok) {
      return 'Nieprawidłowy format e-mail.';
    }
    return null;
  }

  static String? passwordSignInError(String password) {
    if (password.isEmpty) {
      return 'Podaj hasło.';
    }
    return null;
  }

  static String? passwordRegisterError(String password) {
    if (password.length < 6) {
      return 'Hasło musi mieć co najmniej 6 znaków (wymóg Firebase).';
    }
    return null;
  }
}
