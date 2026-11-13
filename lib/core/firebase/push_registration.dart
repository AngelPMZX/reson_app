import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/network/network_service.dart';
import '../theme/reson_theme.dart';
import 'firebase_bootstrap.dart';

/// Hands this device's push address to the backend.
///
/// Behind a provider because messaging is a platform plugin and a test has no
/// platform to ask. The real one is only wired on Android: iOS needs an APNs
/// key that does not exist yet, and the web needs a VAPID key, so asking
/// there would prompt for a permission nothing can honour.
typedef PushRegistrar =
    Future<void> Function(NetworkService service, String language);

Future<void> registerForPush(NetworkService service, String language) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.denied) return;
  final token = await messaging.getToken();
  if (token != null) {
    await service.act('registerDevice', {
      'token': token,
      'language': language,
      'platform': 'android',
    });
  }
  // A token is rotated by the system, not by us, so the new one has to be
  // handed over whenever that happens or the device goes quiet.
  messaging.onTokenRefresh.listen((fresh) async {
    try {
      await service.act('registerDevice', {
        'token': fresh,
        'language': language,
        'platform': 'android',
      });
    } catch (_) {
      /* The next launch registers again. */
    }
  });
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) => registerForPush);

/// Keeps the backend's idea of this device current.
///
/// Rebuilt whenever the session or the language changes, which are exactly
/// the two things a notification needs to be right: who to reach, and which
/// words to use. Registering the same token twice simply overwrites it.
final pushSyncProvider = Provider<void>((ref) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) return;
  final language = ref.watch(localeProvider)?.languageCode ?? 'es';
  final service = ref.read(networkServiceProvider);
  Future<void>(() async {
    try {
      await ref.read(pushRegistrarProvider)(service, language);
    } catch (_) {
      /* Without a push address the app still works, quietly. */
    }
  });
});
