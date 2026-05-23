import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAPodLKyTab8HwhpAc6FolnCWrZ2e0rfWk',
    appId: '1:1033860843007:web:f4d9bb3c7bd861d5b6d3ca',
    messagingSenderId: '1033860843007',
    projectId: 'daybrief-d6bf6',
    authDomain: 'daybrief-d6bf6.firebaseapp.com',
    storageBucket: 'daybrief-d6bf6.firebasestorage.app',
    measurementId: 'G-KNF9G0F1QT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPodLKyTab8HwhpAc6FolnCWrZ2e0rfWk',
    appId: '1:1033860843007:android:f4d9bb3c7bd861d5b6d3ca',
    messagingSenderId: '1033860843007',
    projectId: 'daybrief-d6bf6',
    storageBucket: 'daybrief-d6bf6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAPodLKyTab8HwhpAc6FolnCWrZ2e0rfWk',
    appId: '1:1033860843007:ios:f4d9bb3c7bd861d5b6d3ca',
    messagingSenderId: '1033860843007',
    projectId: 'daybrief-d6bf6',
    storageBucket: 'daybrief-d6bf6.firebasestorage.app',
    iosBundleId: 'com.daybrief.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAPodLKyTab8HwhpAc6FolnCWrZ2e0rfWk',
    appId: '1:1033860843007:ios:f4d9bb3c7bd861d5b6d3ca',
    messagingSenderId: '1033860843007',
    projectId: 'daybrief-d6bf6',
    storageBucket: 'daybrief-d6bf6.firebasestorage.app',
    iosBundleId: 'com.daybrief.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAPodLKyTab8HwhpAc6FolnCWrZ2e0rfWk',
    appId: '1:1033860843007:web:f4d9bb3c7bd861d5b6d3ca',
    messagingSenderId: '1033860843007',
    projectId: 'daybrief-d6bf6',
    authDomain: 'daybrief-d6bf6.firebaseapp.com',
    storageBucket: 'daybrief-d6bf6.firebasestorage.app',
    measurementId: 'G-KNF9G0F1QT',
  );
}
