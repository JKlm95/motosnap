// GENERATED PLACEHOLDER — replace by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Values below are non-secret *client* identifiers only; real Firebase projects
// must be created in the Firebase Console and wired via FlutterFire CLI.
// Until then, `FirebaseInitializer` may still initialize if native config files
// (`google-services.json` / `GoogleService-Info.plist`) are valid for a project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform — '
          'run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'motosnap-mvp',
    authDomain: 'motosnap-mvp.firebaseapp.com',
    storageBucket: 'motosnap-mvp.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyReplaceWithFlutterFireConfigure',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'motosnap-mvp',
    storageBucket: 'motosnap-mvp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyReplaceWithFlutterFireConfigure',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'motosnap-mvp',
    storageBucket: 'motosnap-mvp.appspot.com',
    iosBundleId: 'com.motosnap.motosnap',
  );
}
