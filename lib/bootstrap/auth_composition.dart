import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/session_terminator.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';

/// Composizione dell'auth condivisa dai due entry point (D-01).
typedef AuthComposition = ({
  AuthTokenService service,
  UnauthorizedRecovery? recovery,
  SessionTerminator terminator,
});

/// Factory che ogni entry point passa a `bootstrapApp` (D-01).
typedef AuthCompositionFactory =
    AuthComposition Function({
      required BackendAuthApi api,
      required Future<void> Function() onSessionTeardown,
    });
