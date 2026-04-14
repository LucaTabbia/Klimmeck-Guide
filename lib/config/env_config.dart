import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.0.20:3000/',
  );

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

  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);

  // ============== Dev Auth (Phase 1 only) ==============
  //
  // Questi valori sono letti a runtime da flutter_dotenv, NON con
  // `String.fromEnvironment` (compile-time). Motivo: flutter_dotenv carica
  // `.env` come asset Flutter a runtime — il valore non è disponibile al
  // momento della compilazione, quindi `fromEnvironment` ritornerebbe sempre
  // il defaultValue (pitfall 1 di 01-RESEARCH.md).
  //
  // Phase 11 rimuoverà questo flag insieme a DevAuthTokenService.

  /// Runtime flag letto da `.env` tramite flutter_dotenv.
  ///
  /// Ritorna `true` solo se `DEV_AUTH_ENABLED=true` (case-insensitive) nel
  /// file `.env`. In release build senza `.env` negli assets, ritorna `false`
  /// in modo sicuro (fail-safe su dotenv non inizializzato).
  ///
  /// Usato da `main.dart` per scegliere tra `DevAuthTokenService` (Phase 1)
  /// e `OAuthTokenService` (Phase 11) tramite factory senza type-check.
  static bool get devAuthEnabled {
    try {
      return dotenv.env['DEV_AUTH_ENABLED']?.toLowerCase() == 'true';
    } catch (_) {
      // dotenv non ancora inizializzato (es. test che non chiama loadTestEnv):
      // fail safe — nessun crash, nessuna auth stub attiva per default.
      return false;
    }
  }

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // ============== Cloudinary ==============

  static const String cloudinaryBaseUrl = String.fromEnvironment(
    'CLOUDINARY_BASE_URL',
    defaultValue: 'https://res.cloudinary.com/dzuhywp53/image/upload',
  );

  static String cloudinaryUrl(String assetPath) =>
      '$cloudinaryBaseUrl/$assetPath';

  // ============== App Info ==============

  static const String appName = 'Guida di Klimmeck';

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
