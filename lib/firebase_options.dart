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
    apiKey: 'AIzaSyCHPaidCAiBePq6Mna7u7ChhW94MRUS74s',
    appId: '1:704759637184:web:6e1725222adfc75b33f925',
    messagingSenderId: '704759637184',
    projectId: 'smart-study-app-77b95',
    authDomain: 'smart-study-app-77b95.firebaseapp.com',
    storageBucket: 'smart-study-app-77b95.firebasestorage.app',
    databaseURL: 'smart-study-app-77b95-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiajUe_l3mkOTbFvkbP7-1tQklfbZdLfA',
    appId: '1:704759637184:android:5dfe484349a1a4d033f925',
    messagingSenderId: '704759637184',
    projectId: 'smart-study-app-77b95',
    storageBucket: 'smart-study-app-77b95.firebasestorage.app',
    databaseURL: 'smart-study-app-77b95-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBiu2Md-fbF4lKLwgRlE3Fl30ain1gEENw',
    appId: '1:704759637184:ios:c90a27f692ae5a1e33f925',
    messagingSenderId: '704759637184',
    projectId: 'smart-study-app-77b95',
    storageBucket: 'smart-study-app-77b95.firebasestorage.app',
    iosBundleId: 'com.example.smartStudyApp',
    databaseURL: 'smart-study-app-77b95-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBiu2Md-fbF4lKLwgRlE3Fl30ain1gEENw',
    appId: '1:704759637184:ios:c90a27f692ae5a1e33f925',
    messagingSenderId: '704759637184',
    projectId: 'smart-study-app-77b95',
    storageBucket: 'smart-study-app-77b95.firebasestorage.app',
    iosBundleId: 'com.example.smartStudyApp',
    databaseURL: 'smart-study-app-77b95-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCHPaidCAiBePq6Mna7u7ChhW94MRUS74s',
    appId: '1:704759637184:web:fcf55ff1eea6818333f925',
    messagingSenderId: '704759637184',
    projectId: 'smart-study-app-77b95',
    authDomain: 'smart-study-app-77b95.firebaseapp.com',
    storageBucket: 'smart-study-app-77b95.firebasestorage.app',
    databaseURL: 'smart-study-app-77b95-default-rtdb.firebaseio.com',
  );
}
