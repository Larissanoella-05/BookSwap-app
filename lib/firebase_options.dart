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
    apiKey: 'AIzaSyCaMmtVyOofMOdI_pla9SYETLTzZSX8ma4',
    appId: '1:162993444111:web:your-web-app-id',
    messagingSenderId: '162993444111',
    projectId: 'bookswap-app-e29b4',
    authDomain: 'bookswap-app-e29b4.firebaseapp.com',
    storageBucket: 'bookswap-app-e29b4.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCaMmtVyOofMOdI_pla9SYETLTzZSX8ma4',
    appId: '1:162993444111:android:bookswap123456789',
    messagingSenderId: '162993444111',
    projectId: 'bookswap-app-e29b4',
    storageBucket: 'bookswap-app-e29b4.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCaMmtVyOofMOdI_pla9SYETLTzZSX8ma4',
    appId: '1:162993444111:ios:your-ios-app-id',
    messagingSenderId: '162993444111',
    projectId: 'bookswap-app-e29b4',
    storageBucket: 'bookswap-app-e29b4.appspot.com',
    iosBundleId: 'com.example.bookswapApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCaMmtVyOofMOdI_pla9SYETLTzZSX8ma4',
    appId: '1:162993444111:macos:your-macos-app-id',
    messagingSenderId: '162993444111',
    projectId: 'bookswap-app-e29b4',
    storageBucket: 'bookswap-app-e29b4.appspot.com',
    iosBundleId: 'com.example.bookswapApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCaMmtVyOofMOdI_pla9SYETLTzZSX8ma4',
    appId: '1:162993444111:windows:bookswap123456789',
    messagingSenderId: '162993444111',
    projectId: 'bookswap-app-e29b4',
    authDomain: 'bookswap-app-e29b4.firebaseapp.com',
    storageBucket: 'bookswap-app-e29b4.appspot.com',
  );
}