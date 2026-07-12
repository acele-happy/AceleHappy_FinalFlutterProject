// Run `flutterfire configure` to replace this file with your project credentials.
// See README.md for setup instructions.

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGtcptbg5sNao3KbwNlNDQs-ncrGitRm0',
    appId: '1:102017950403:web:d6026700e5740ba4b8f876',
    messagingSenderId: '102017950403',
    projectId: 'constore-e2314',
    authDomain: 'constore-e2314.firebaseapp.com',
    storageBucket: 'constore-e2314.firebasestorage.app',
    measurementId: 'G-H404B24JDE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARFtGTr3kHjk7bIB7F-w1DFggnJi4mzps',
    appId: '1:102017950403:android:9f37368ed657d0d4b8f876',
    messagingSenderId: '102017950403',
    projectId: 'constore-e2314',
    storageBucket: 'constore-e2314.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6vgclk9oMHAu1diXaLxzkr4XINEWO_fQ',
    appId: '1:102017950403:ios:0066959fbd5289a4b8f876',
    messagingSenderId: '102017950403',
    projectId: 'constore-e2314',
    storageBucket: 'constore-e2314.firebasestorage.app',
    iosBundleId: 'com.alu.venturelink.aluVentureLink',
  );
}
