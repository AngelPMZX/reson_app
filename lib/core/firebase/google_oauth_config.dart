// Public OAuth client identifiers. Complete after downloading updated Firebase files.
// Set iosReady only after adding REVERSED_CLIENT_ID to Runner's URL schemes.
abstract final class GoogleOAuthConfig {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const iosReady = bool.fromEnvironment('GOOGLE_IOS_READY');
}
