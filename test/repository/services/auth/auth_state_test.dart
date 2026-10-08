import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

import '../../../helpers/auth_fixtures.dart';

void main() {
  group('AuthUnauthenticated', () {
    test('defaults to signedOut', () {
      expect(
        const AuthUnauthenticated().reason,
        UnauthenticatedReason.signedOut,
      );
    });

    test('compares by reason', () {
      const expired = AuthUnauthenticated(
        reason: UnauthenticatedReason.sessionExpired,
      );

      expect(expired, isNot(const AuthUnauthenticated()));
      expect(
        expired,
        const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
      );
    });
  });

  test('AuthAuthenticated toString never leaks the access token', () {
    final state = AuthAuthenticated(
      user: buildTestUser(),
      accessToken: 'tok-secret',
    );

    expect(state.toString(), isNot(contains('tok-secret')));
  });
}
