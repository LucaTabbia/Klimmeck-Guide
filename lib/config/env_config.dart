/// Environment configuration for the Klimmeck Guide app.
///
/// This class centralizes all environment-specific values like API URLs,
/// keys, and other configuration that may change between environments.
///
/// To override at build time, use:
/// ```bash
/// flutter run --dart-define=GRAPHQL_HTTP_URL=https://your-server.com/api/graphql
/// ```
class EnvConfig {
  EnvConfig._();

  // ============== GraphQL Configuration ==============

  static const String graphqlHttpUrl = String.fromEnvironment(
    'GRAPHQL_HTTP_URL',
    defaultValue: 'http://192.168.0.20:3000/api/graphql',
  );

  static const String graphqlWsUrl = String.fromEnvironment(
    'GRAPHQL_WS_URL',
    defaultValue: 'ws://192.168.0.20:3000/api/graphql',
  );

  // ============== Timeouts ==============

  static const int queryTimeoutSeconds = int.fromEnvironment(
    'QUERY_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const int wsInactivityTimeoutSeconds = int.fromEnvironment(
    'WS_INACTIVITY_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  // ============== Environment Flags ==============

  static const bool isDebug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // ============== Cloudinary ==============

  static const String cloudinaryBaseUrl = String.fromEnvironment(
    'CLOUDINARY_BASE_URL',
    defaultValue: 'https://res.cloudinary.com/dzuhywp53/image/upload',
  );

  static String cloudinaryUrl(String assetPath) => '$cloudinaryBaseUrl/$assetPath';

  // ============== App Info ==============

  static const String appName = 'Guida di Klimmeck';

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}

