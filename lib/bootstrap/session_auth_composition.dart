import 'package:klimmeck_guide/bootstrap/auth_composition.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';
import 'package:klimmeck_guide/repository/services/auth/session_auth_token_service.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';

/// Factory dell'entry point di produzione: solo la sessione reale (D-01).
AuthComposition buildSessionAuthComposition({
  required BackendAuthApi api,
  required Future<void> Function() onSessionTeardown,
}) {
  final service = SessionAuthTokenService(
    api: api,
    store: SecureSessionStore(),
    browser: const FlutterWebAuth2BrowserAuthenticator(),
    backendBaseUrl: Uri.parse(EnvConfig.baseUrl),
    onSessionTeardown: onSessionTeardown,
  );
  return (service: service, recovery: service, terminator: service);
}
