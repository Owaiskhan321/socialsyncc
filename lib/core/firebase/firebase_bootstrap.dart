import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';
import '../logger/app_logger.dart';
import 'fcm_service.dart';

/// Firebase + Google Sign-In one-time setup at app launch.
abstract final class FirebaseBootstrap {
  static const _iosGoogleClientId =
      '266829292784-r0dg5vm8pd2v71b8i2d1l1tkbqt59g3l.apps.googleusercontent.com';
  static const _webServerClientId =
      '266829292784-in7h1nmi96l5rmkf2l8so009hu9aeneb.apps.googleusercontent.com';

  static Future<void> initialize() async {
    if (kIsWeb) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Firebase initialized');

    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _iosGoogleClientId
          : null,
      serverClientId: _webServerClientId,
    );
    AppLogger.i('GoogleSignIn initialized');

    await FcmService.initialize();
  }
}
