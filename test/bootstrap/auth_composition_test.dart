import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/bootstrap/auth_composition.dart';
import 'package:klimmeck_guide/bootstrap/dev_auth_composition.dart';
import 'package:klimmeck_guide/bootstrap/session_auth_composition.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/session_auth_token_service.dart';

import '../helpers/fixtures/dev_auth_env.dart';
import '../helpers/mocks.dart';

Future<void> _noTeardown() async {}

AuthComposition _composeWith(AuthCompositionFactory factory) {
  final composition = factory(
    api: MockBackendAuthApi(),
    onSessionTeardown: _noTeardown,
  );
  addTearDown(composition.service.dispose);
  return composition;
}

void main() {
  tearDown(EnvConfig.resetRuntimeOverrides);

  test(
    'the session factory composes the session service as its own recovery and terminator (D-01)',
    () {
      final composition = _composeWith(buildSessionAuthComposition);

      expect(composition.service, isA<SessionAuthTokenService>());
      expect(identical(composition.recovery, composition.service), isTrue);
      expect(identical(composition.terminator, composition.service), isTrue);
    },
  );

  test(
    'the dev factory composes the dev bypass when DEV_AUTH_ENABLED is true (D-01)',
    () async {
      await loadTestEnv(devAuthEnabled: 'true');

      final composition = _composeWith(buildDevAuthComposition);

      expect(composition.service, isA<DevAuthTokenService>());
      expect(composition.recovery, isNull);
      expect(identical(composition.terminator, composition.service), isTrue);
    },
  );

  test(
    'the dev factory falls back to the session service when DEV_AUTH_ENABLED is not true (D-01)',
    () async {
      await loadTestEnv(devAuthEnabled: 'false');

      final composition = _composeWith(buildDevAuthComposition);

      expect(composition.service, isA<SessionAuthTokenService>());
      expect(identical(composition.recovery, composition.service), isTrue);
    },
  );

  group('without runtime overrides', () {
    setUp(EnvConfig.resetRuntimeOverrides);

    test(
      'the dev factory falls back to the session service without runtime overrides (D-01)',
      () {
        final composition = _composeWith(buildDevAuthComposition);

        expect(composition.service, isA<SessionAuthTokenService>());
      },
    );
  });
}
