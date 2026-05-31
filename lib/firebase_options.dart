import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
///
/// Provided as a placeholder for compilation. To link this to your actual Firebase project,
/// run `flutterfire configure` or replace these placeholders with your real credentials.
class DefaultFirebaseOptions {
  /// Resolves the Firebase configurations based on active OS platform.
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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-KdIdBwAbDrlWshyeWcmbYqpTavju0G0',
    appId: '1:522146566714:web:81f1bf055302d94fdbdb03',
    messagingSenderId: '522146566714',
    projectId: 'squadfill-4f0fa',
    authDomain: 'squadfill-4f0fa.firebaseapp.com',
    storageBucket: 'squadfill-4f0fa.firebasestorage.app',
    measurementId: 'G-JR4P3SS4RP',
  );

  /// Web platform Firebase configuration credentials.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcsxUGlrZSEoiNLBqjrrjyFGSN7kwchz8',
    appId: '1:522146566714:android:04c5dcca0ba40f83dbdb03',
    messagingSenderId: '522146566714',
    projectId: 'squadfill-4f0fa',
    storageBucket: 'squadfill-4f0fa.firebasestorage.app',
  );

  /// Android platform Firebase configuration credentials.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAv9DVerbT94jFX2T5aUS-rne_LWQWSqmY',
    appId: '1:522146566714:ios:dd7610a02dd644bfdbdb03',
    messagingSenderId: '522146566714',
    projectId: 'squadfill-4f0fa',
    storageBucket: 'squadfill-4f0fa.firebasestorage.app',
    iosBundleId: 'com.squadfill.squadfill',
  );

  /// iOS platform Firebase configuration credentials.
}