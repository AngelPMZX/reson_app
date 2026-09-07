import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../firebase_options.dart';

// Initialization is owned by this provider; native runners must not initialize
// a second Firebase app. Nullable return supports an explicit UI-only preview.
Future<AuthRepository?> initializeAuth() async {
  if (const bool.fromEnvironment('RESON_PREVIEW_ONLY')) {
    return null;
  }
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  return FirebaseAuthRepository(FirebaseAuth.instanceFor(app: app));
}

final authRepositoryProvider = FutureProvider<AuthRepository?>(
  (ref) => initializeAuth(),
);

final authSessionProvider = StreamProvider<AuthIdentity?>((ref) async* {
  final repository = await ref.watch(authRepositoryProvider.future);
  if (repository == null) {
    yield null;
  } else {
    yield* repository.watchSession();
  }
});
