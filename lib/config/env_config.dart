import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/config/insecure_transport_error.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

/// Environment configuration for the Klimmeck Guide app.
///
/// This class centralizes all environment-specific values like API URLs,
/// keys, and other configuration that may change between environments.
///
/// Backend URLs (`BASE_URL`, `GRAPHQL_HTTP_URL`, `GRAPHQL_WS_URL`) are
/// resolved at runtime with this priority:
/// 1. the runtime overrides installed by the dev entry point
///    (`installRuntimeOverrides`, values of `.env`);
/// 2. a `--dart-define` of the same name
///    (`--dart-define-from-file=env/<name>.json`);
/// 3. the built-in default.
class EnvConfig {
  EnvConfig._();

  // ============== Backend URLs ==============
  //
  // Valori non segreti: in release arrivano da `--dart-define-from-file` (D-02).

  static const String _baseUrlDefine = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.0.20:3000/',
  );

  static const String _graphqlHttpUrlDefine = String.fromEnvironment(
    'GRAPHQL_HTTP_URL',
    defaultValue: 'http://192.168.0.20:3000/api/graphql',
  );

  static const String _graphqlWsUrlDefine = String.fromEnvironment(
    'GRAPHQL_WS_URL',
    defaultValue: 'ws://192.168.0.20:3000/api/graphql',
  );

  static String get baseUrl => _runtimeValue('BASE_URL') ?? _baseUrlDefine;

  static String get graphqlHttpUrl =>
      _runtimeValue('GRAPHQL_HTTP_URL') ?? _graphqlHttpUrlDefine;

  static String get graphqlWsUrl =>
      _runtimeValue('GRAPHQL_WS_URL') ?? _graphqlWsUrlDefine;

  static Map<String, String> _runtimeOverrides = const {};

  /// Valori `.env` installati dall'entry point di sviluppo (D-01): l'entry point
  /// di produzione non li installa mai.
  static void installRuntimeOverrides(Map<String, String> values) =>
      _runtimeOverrides = Map.unmodifiable(values);

  @visibleForTesting
  static void resetRuntimeOverrides() => _runtimeOverrides = const {};

  /// Valore dell'override per [key], oppure `null` se assente o vuoto: in quel
  /// caso vale il `--dart-define` o il default.
  static String? _runtimeValue(String key) {
    final value = _runtimeOverrides[key]?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  // ============== Transport (D-03b) ==============
  //
  // dart:io ignora la cleartext policy di Android: il rifiuto è lato Dart.

  /// In release lancia [InsecureTransportError] se un URL del backend non è
  /// `https`/`wss`; fuori release si limita a loggare i nomi delle chiavi.
  static void requireSecureTransport({bool isRelease = kReleaseMode}) {
    final offending = _cleartextKeys();
    if (offending.isEmpty) return;
    if (isRelease) throw InsecureTransportError(offending);
    appLog(
      '[EnvConfig] cleartext backend URLs outside release: '
      '${offending.join(', ')}',
    );
  }

  static List<String> _cleartextKeys() => [
    if (!_hasScheme(baseUrl, 'https')) 'BASE_URL',
    if (!_hasScheme(graphqlHttpUrl, 'https')) 'GRAPHQL_HTTP_URL',
    if (!_hasScheme(graphqlWsUrl, 'wss')) 'GRAPHQL_WS_URL',
  ];

  static bool _hasScheme(String url, String scheme) =>
      Uri.tryParse(url)?.scheme.toLowerCase() == scheme;

  // ============== Timeouts ==============

  static const int queryTimeoutSeconds = int.fromEnvironment(
    'QUERY_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const int wsInactivityTimeoutSeconds = int.fromEnvironment(
    'WS_INACTIVITY_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const int wsPingIntervalSeconds = int.fromEnvironment(
    'WS_PING_INTERVAL_SECONDS',
    defaultValue: 25,
  );

  static const int wsConnectTimeoutSeconds = int.fromEnvironment(
    'WS_CONNECT_TIMEOUT_SECONDS',
    defaultValue: 10,
  );

  // ============== Environment Flags ==============

  static const bool isDebug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: !kReleaseMode,
  );

  // ============== Dev Auth (bypass finché non esistono le chiavi Twitch, D-23) ==============
  //
  // Il flag è letto dai runtime override installati dall'entry point di
  // sviluppo: senza override (entry point di produzione) vale `false`.

  /// Ritorna `true` solo se `DEV_AUTH_ENABLED=true` (case-insensitive, spazi
  /// attorno ignorati come per `DEV_AUTH_START_SIGNED_OUT`) negli override.
  ///
  /// Usato da `buildDevAuthComposition` (entry point `main_dev.dart`) per
  /// scegliere tra `DevAuthTokenService` e `SessionAuthTokenService`.
  static bool get devAuthEnabled =>
      _runtimeValue('DEV_AUTH_ENABLED')?.toLowerCase() == 'true';

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: !kReleaseMode,
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
