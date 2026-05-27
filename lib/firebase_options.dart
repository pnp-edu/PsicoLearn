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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyATeI14K6CbGVM7FEKUZP4wLON32HsNaO8',
    appId: '1:474933138096:web:0fa1e558ce48abf98ba175',
    messagingSenderId: '474933138096',
    projectId: 'psico-l',
    authDomain: 'psico-l.firebaseapp.com',
    storageBucket: 'psico-l.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATeI14K6CbGVM7FEKUZP4wLON32HsNaO8',
    appId: '1:474933138096:android:ba9a5be751b8ab1c8ba175',
    messagingSenderId: '474933138096',
    projectId: 'psico-l',
    storageBucket: 'psico-l.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATeI14K6CbGVM7FEKUZP4wLON32HsNaO8',
    appId: '1:474933138096:ios:fakeappid', // Fallback, not currently configured
    messagingSenderId: '474933138096',
    projectId: 'psico-l',
    storageBucket: 'psico-l.firebasestorage.app',
    iosBundleId: 'com.psicolearn.app',
  );
}
