import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/auth_session_fixtures.dart';

void main() {
  group('AuthSession.fromJson', () {
    test('parses tokens, expiry and user', () {
      final session = AuthSession.fromJson(authSessionJson(userId: 'u1'));

      expect(session.accessToken, 'a');
      expect(session.refreshToken, 'r');
      expect(session.accessTokenExpiresAt, DateTime.utc(2026, 10, 6, 12, 15));
      expect(session.user.id, 'u1');
    });

    test('throws FormatException when expiry is missing', () {
      final json = authSessionJson()..remove('accessTokenExpiresAt');

      expect(() => AuthSession.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when expiry is not parsable', () {
      final json = authSessionJson(expiresAt: 'not-a-date');

      expect(() => AuthSession.fromJson(json), throwsFormatException);
    });
  });

  group('AuthSession value semantics', () {
    test('is equatable on all four fields', () {
      expect(buildAuthSession(), buildAuthSession());
      expect(
        buildAuthSession(refreshToken: 'other'),
        isNot(buildAuthSession()),
      );
      expect(buildAuthSession(user: buildTestUser()), buildAuthSession());
    });

    test('toString never leaks tokens', () {
      final session = buildAuthSession(
        accessToken: 'a-secret-access',
        refreshToken: 'r-secret-refresh',
      );

      expect(session.toString(), isNot(contains('a-secret-access')));
      expect(session.toString(), isNot(contains('r-secret-refresh')));
    });
  });
}
