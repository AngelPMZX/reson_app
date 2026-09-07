import '../domain/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

String authErrorMessage(Object error, AppLocalizations s) {
  if (error is! AuthFailure) return s.authGeneric;
  return switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => s.authInvalid,
    'invalid-email' => s.invalidEmail,
    'email-already-in-use' => s.authEmailUsed,
    'weak-password' => s.authWeak,
    'network-request-failed' => s.authNetwork,
    'too-many-requests' => s.authRate,
    'user-disabled' => s.authDisabled,
    'operation-not-allowed' => s.authUnavailable,
    _ => s.authGeneric,
  };
}
