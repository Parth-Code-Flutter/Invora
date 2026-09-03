// Firebase options from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist (project creovobilling).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web in this app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android and iOS in this app.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0kqkiPvmlRzmazXMPfGgOIKbGn6sonJ0',
    appId: '1:927000045835:android:f939e168a25acdae97da0e',
    messagingSenderId: '927000045835',
    projectId: 'creovobilling',
    storageBucket: 'creovobilling.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZQqc5Zmx6Y4q10PAygniT8xA1nYEe8j8',
    appId: '1:927000045835:ios:e25e5e82a2c6385097da0e',
    messagingSenderId: '927000045835',
    projectId: 'creovobilling',
    storageBucket: 'creovobilling.firebasestorage.app',
    iosBundleId: 'com.creovo.billing',
  );
}
