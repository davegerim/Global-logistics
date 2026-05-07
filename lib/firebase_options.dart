import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Default Firebase options for current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAd7tw80uWFZ3NRcuDoAJLw1LgtYhzKMmo',
    appId: '1:636272952328:android:bb452e5ba70807ae1f3dbd',
    messagingSenderId: '636272952328',
    projectId: 'global-logistics-push-notif',
    storageBucket: 'global-logistics-push-notif.firebasestorage.app',
  );
}
