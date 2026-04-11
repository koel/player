class AppStrings {
  AppStrings._();

  static const String appName = 'Koel';

  /// Web OAuth Client ID used as the `serverClientId` for Google Sign-In.
  /// Injected at build time via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}
