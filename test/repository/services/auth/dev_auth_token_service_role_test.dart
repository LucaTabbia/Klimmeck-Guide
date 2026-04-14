import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';

import '../../../helpers/fixtures/dev_auth_env.dart';

/// RED — role switching parametrico (DEV-AUTH-03).
/// Diventerà GREEN dopo Plan 02.
void main() {
  group('DevAuthTokenService role switching', () {
    for (final entry in {
      'adventurer': RoleType.adventurer,
      'guard': RoleType.guard,
      'innkeeper': RoleType.innkeeper,
    }.entries) {
      test('DEV_AUTH_ROLE=${entry.key} → user.role == ${entry.value}', () async {
        await loadTestEnv(role: entry.key);
        final service = DevAuthTokenService();
        await service.initialize();

        final authenticated = await service.authStateStream
            .firstWhere((s) => s is AuthAuthenticated) as AuthAuthenticated;

        expect(authenticated.user.role, equals(entry.value));
        service.dispose();
      });
    }

    test('DEV_AUTH_ROLE=UnknownRole → fallback a RoleType.adventurer', () async {
      await loadTestEnv(role: 'UnknownRole');
      final service = DevAuthTokenService();
      await service.initialize();

      final authenticated = await service.authStateStream
          .firstWhere((s) => s is AuthAuthenticated) as AuthAuthenticated;

      expect(authenticated.user.role, equals(RoleType.adventurer));
      service.dispose();
    });
  });
}
