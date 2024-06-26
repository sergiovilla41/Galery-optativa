// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
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
    apiKey: 'AIzaSyDJUiGfZAJJqrb6E-38yN_QScQ2mE2p-XY',
    appId: '1:498804878181:web:429bbeb4a2a2c20f5b8f8c',
    messagingSenderId: '498804878181',
    projectId: 'my-galery-e435b',
    authDomain: 'my-galery-e435b.firebaseapp.com',
    storageBucket: 'my-galery-e435b.appspot.com',
    measurementId: 'G-44L8DTSCTB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBTwNGdpvrDLi1Phf_1LR99gzMX3e4muPg',
    appId: '1:498804878181:android:37a2730fa48ca3085b8f8c',
    messagingSenderId: '498804878181',
    projectId: 'my-galery-e435b',
    storageBucket: 'my-galery-e435b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCutOxZihspukM9QAENhJ6wd2yXQc6gXt4',
    appId: '1:498804878181:ios:4fa8270f903eefb55b8f8c',
    messagingSenderId: '498804878181',
    projectId: 'my-galery-e435b',
    storageBucket: 'my-galery-e435b.appspot.com',
    iosBundleId: 'com.example.miAppOptativa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCutOxZihspukM9QAENhJ6wd2yXQc6gXt4',
    appId: '1:498804878181:ios:4fa8270f903eefb55b8f8c',
    messagingSenderId: '498804878181',
    projectId: 'my-galery-e435b',
    storageBucket: 'my-galery-e435b.appspot.com',
    iosBundleId: 'com.example.miAppOptativa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDJUiGfZAJJqrb6E-38yN_QScQ2mE2p-XY',
    appId: '1:498804878181:web:2185d9317521affc5b8f8c',
    messagingSenderId: '498804878181',
    projectId: 'my-galery-e435b',
    authDomain: 'my-galery-e435b.firebaseapp.com',
    storageBucket: 'my-galery-e435b.appspot.com',
    measurementId: 'G-R5NB8E4J4K',
  );
}
