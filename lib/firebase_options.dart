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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCv56yKNkBLTq0wGBGk6RQTgx-TMy0ILQg',
    appId: '1:307953779464:android:48c25eaed3cdb1109522bd',
    messagingSenderId: '307953779464',
    projectId: 'shamcrm-23800',
    storageBucket: 'shamcrm-23800.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOELiYITNKdUwsYtXVh4R1uNPrOE49Rx8',
    appId: '1:307953779464:ios:81f3c7d5cccd77a89522bd',
    messagingSenderId: '307953779464',
    projectId: 'shamcrm-23800',
    storageBucket: 'shamcrm-23800.appspot.com',
    iosBundleId: 'com.example.crmTaskManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBOELiYITNKdUwsYtXVh4R1uNPrOE49Rx8',
    appId: '1:307953779464:ios:81f3c7d5cccd77a89522bd',
    messagingSenderId: '307953779464',
    projectId: 'shamcrm-23800',
    storageBucket: 'shamcrm-23800.appspot.com',
    iosBundleId: 'com.example.crmTaskManager',
  );
}