import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACqoXdvV3kh1N8Jj1b6tVHFQrqXB8j4ng',
    appId: '1:357865467948:android:351a0329f45dc2145da189',
    messagingSenderId: '357865467948',
    projectId: 'virtualwardrobe-19372',
    storageBucket: 'virtualwardrobe-19372.appspot.com',
    androidClientId:
        '357865467948-2h7qvq5ub7qqtk4gvp0rvr8p7qqbqc6q.apps.googleusercontent.com',
  );
}
