import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client configuration from the Firebase registrations supplied by the
/// project owner. Keep native files and these options in sync when changing apps.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Reson supports Android, iOS and web.'),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyC-n8KxhsWli_UIcFDvaUzmjxFIH-Kzc9g',
    appId: '1:1066611577415:web:c3b73c214d780fda309762',
    messagingSenderId: '1066611577415',
    projectId: 'reson-app',
    authDomain: 'reson-app.firebaseapp.com',
    storageBucket: 'reson-app.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyC9KEGV09idbKC3Nc4NBJrk_Wqraj_vZY4',
    appId: '1:1066611577415:android:849e1966459bdec1309762',
    messagingSenderId: '1066611577415',
    projectId: 'reson-app',
    storageBucket: 'reson-app.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCX9ZmJfZStdy0zbDZjbYjuUQt2lIL9LNA',
    appId: '1:1066611577415:ios:6e3ee109a82a9664309762',
    messagingSenderId: '1066611577415',
    projectId: 'reson-app',
    storageBucket: 'reson-app.firebasestorage.app',
    iosBundleId: 'com.thedarkingstudios.reson',
  );
}
