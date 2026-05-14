import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/core/firebase/firebase_initializer.dart';

void main() {
  test(
    'FirebaseInitializer — duplicate-app traktowany jak już skonfigurowane',
    () {
      final dup = FirebaseException(
        plugin: 'core',
        code: 'duplicate-app',
        message: 'A Firebase App named "[DEFAULT]" already exists',
      );
      expect(
        FirebaseInitializer.isDuplicateDefaultAppErrorForTesting(dup),
        isTrue,
      );
    },
  );

  test('FirebaseInitializer — inny kod FirebaseException to nie duplicate', () {
    final other = FirebaseException(
      plugin: 'core',
      code: 'no-app',
      message: 'no app',
    );
    expect(
      FirebaseInitializer.isDuplicateDefaultAppErrorForTesting(other),
      isFalse,
    );
  });
}
