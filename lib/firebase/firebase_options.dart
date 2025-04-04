// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de configuración predeterminadas para el uso de Firebase para la app DragonBall Card Game.
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
          'DefaultFirebaseOptions has not been configured for macos - '
          'you can create this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for windows - '
          'you can create this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for linux - '
          'you can create this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6T_Vf-7ShXcbLOMulrVuRGfZE41M9Y-w',
    appId: '1:1074439862642:web:cb701f0bff02acb7f3c5eb',
    messagingSenderId: '1074439862642',
    projectId: 'dragonball-cardgame',
    authDomain: 'dragonball-cardgame.firebaseapp.com',
    storageBucket: 'dragonball-cardgame.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6T_Vf-7ShXcbLOMulrVuRGfZE41M9Y-w',
    appId: '1:1074439862642:android:cb701f0bff02acb7f3c5eb',
    messagingSenderId: '1074439862642',
    projectId: 'dragonball-cardgame',
    storageBucket: 'dragonball-cardgame.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6T_Vf-7ShXcbLOMulrVuRGfZE41M9Y-w',
    appId: '1:1074439862642:ios:cb701f0bff02acb7f3c5eb',
    messagingSenderId: '1074439862642',
    projectId: 'dragonball-cardgame',
    storageBucket: 'dragonball-cardgame.firebasestorage.app',
    iosClientId: '1074439862642-xxxxx.apps.googleusercontent.com',
    iosBundleId: 'com.dragonballcardgame.app',
  );
}
