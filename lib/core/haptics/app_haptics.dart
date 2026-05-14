import 'package:flutter/services.dart';

/// Centralne wywołania haptyczne (Flutter [HapticFeedback]).
///
/// API Flutter nie zgłasza wyjątków przy braku silnika — metody są no-op tam,
/// gdzie haptyka nie jest dostępna; [try/catch] zabezpiecza przed hipotetycznymi
/// błędami platformowymi.
abstract final class AppHaptics {
  static void _safe(void Function() fn) {
    try {
      fn();
    } on Object {
      // Ignoruj — UI nie może paść na haptyce.
    }
  }

  static void selection() => _safe(HapticFeedback.selectionClick);

  static void lightImpact() => _safe(HapticFeedback.lightImpact);

  static void success() => _safe(HapticFeedback.mediumImpact);

  static void warning() => _safe(HapticFeedback.lightImpact);

  static void error() => _safe(HapticFeedback.heavyImpact);
}
