import 'package:klimmeck_guide/bootstrap/auth_composition.dart';
import 'package:klimmeck_guide/bootstrap/session_auth_composition.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

/// Factory dell'entry point di sviluppo: unico file di `lib/bootstrap/` che
/// conosce il bypass dev (Phase 11 D-23..D-30). Senza `DEV_AUTH_ENABLED=true`
/// compone la sessione reale. Il bypass non ha recovery (nessun refresh).
AuthComposition buildDevAuthComposition({
  required BackendAuthApi api,
  required Future<void> Function() onSessionTeardown,
}) {
  if (!EnvConfig.devAuthEnabled) {
    return buildSessionAuthComposition(
      api: api,
      onSessionTeardown: onSessionTeardown,
    );
  }
  final dev = DevAuthTokenService(
    meSource: api,
    onSessionTeardown: onSessionTeardown,
  );
  return (service: dev, recovery: null, terminator: dev);
}
