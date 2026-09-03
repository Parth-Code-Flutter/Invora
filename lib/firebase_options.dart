// Android Firebase options from android/app/google-services.json
// (project creovobilling). iOS needs GoogleService-Info.plist later.

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
        throw UnsupportedError(
          'Add GoogleService-Info.plist before running Firebase on iOS.',
        );
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android in this app.',
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
}
