// File generated manually from google-services.json
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtOfrbG15isjF3iv5mbycHVYrq7vNcbOg',
    appId: '1:742231820930:android:12300bfe6a158562fd829b',
    messagingSenderId: '742231820930',
    projectId: 'drinkdriveapp-3d02c',
    storageBucket: 'drinkdriveapp-3d02c.firebasestorage.app',
  );

  // Datos extraídos de google-services.json

  // Para web - IMPORTANTE: Debes crear una app web en Firebase Console

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2_sgWlvB8WINWH0L6BVgtdx9cNnU0dUU',
    appId: '1:742231820930:web:a84f9a10c8a21e7cfd829b',
    messagingSenderId: '742231820930',
    projectId: 'drinkdriveapp-3d02c',
    authDomain: 'drinkdriveapp-3d02c.firebaseapp.com',
    storageBucket: 'drinkdriveapp-3d02c.firebasestorage.app',
    measurementId: 'G-60QSG7T87P',
  );

  // y reemplazar estos valores con los correctos

  // Placeholder para iOS - necesitarás GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtOfrbG15isjF3iv5mbycHVYrq7vNcbOg',
    appId: '1:742231820930:ios:REEMPLAZAR_CON_APP_ID_IOS',
    messagingSenderId: '742231820930',
    projectId: 'drinkdriveapp-3d02c',
    storageBucket: 'drinkdriveapp-3d02c.firebasestorage.app',
    iosBundleId: 'com.example.ddApp',
  );

  // Placeholder para macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCtOfrbG15isjF3iv5mbycHVYrq7vNcbOg',
    appId: '1:742231820930:ios:REEMPLAZAR_CON_APP_ID_MACOS',
    messagingSenderId: '742231820930',
    projectId: 'drinkdriveapp-3d02c',
    storageBucket: 'drinkdriveapp-3d02c.firebasestorage.app',
    iosBundleId: 'com.example.ddApp',
  );

  // Placeholder para Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCtOfrbG15isjF3iv5mbycHVYrq7vNcbOg',
    appId: '1:742231820930:web:REEMPLAZAR_CON_APP_ID_WINDOWS',
    messagingSenderId: '742231820930',
    projectId: 'drinkdriveapp-3d02c',
    authDomain: 'drinkdriveapp-3d02c.firebaseapp.com',
    storageBucket: 'drinkdriveapp-3d02c.firebasestorage.app',
  );
}