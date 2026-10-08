import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/access_token_lifetime.dart';

import '../../../helpers/auth_session_fixtures.dart';

String _jwtWithPayload(Map<String, Object?> payload) {
  final encoded = base64Url
      .encode(utf8.encode(jsonEncode(payload)))
      .replaceAll('=', '');
  return 'header.$encoded.signature';
}

void main() {
  group('accessTokenLifetime', () {
    test('reads exp minus iat', () {
      expect(
        accessTokenLifetime(_jwtWithPayload({'iat': 1000, 'exp': 1900})),
        const Duration(seconds: 900),
      );
    });

    test('returns null for malformed tokens', () {
      expect(accessTokenLifetime('only.two'), isNull);
      expect(accessTokenLifetime('a.!!!.c'), isNull);
      expect(accessTokenLifetime('a.${base64Url.encode([1, 2, 3])}.c'), isNull);
    });

    test('returns null when claims are missing or inverted', () {
      expect(accessTokenLifetime(_jwtWithPayload({'exp': 1900})), isNull);
      expect(accessTokenLifetime(_jwtWithPayload({'iat': 1000})), isNull);
      expect(
        accessTokenLifetime(_jwtWithPayload({'iat': 1900, 'exp': 1000})),
        isNull,
      );
    });
  });

  group('refreshDelayFor', () {
    test('uses lifetime minus margin regardless of clock skew', () {
      final delay = refreshDelayFor(
        accessToken: buildTestJwt(),
        expiresAt: testNow.subtract(const Duration(hours: 5)),
        now: testNow.add(const Duration(days: 1)),
      );

      expect(delay, const Duration(seconds: 840));
    });

    test('falls back to expiresAt - now for undecodable tokens', () {
      expect(
        refreshDelayFor(
          accessToken: 'opaque',
          expiresAt: testNow.add(const Duration(seconds: 900)),
          now: testNow,
        ),
        const Duration(seconds: 840),
      );
    });

    test('applies the floor when the delay is too short', () {
      expect(
        refreshDelayFor(
          accessToken: 'opaque',
          expiresAt: testNow.add(const Duration(seconds: 60)),
          now: testNow,
        ),
        const Duration(seconds: 30),
      );
    });

    test('applies the floor when expiresAt is in the past', () {
      expect(
        refreshDelayFor(
          accessToken: 'opaque',
          expiresAt: testNow.subtract(const Duration(hours: 1)),
          now: testNow,
        ),
        const Duration(seconds: 30),
      );
    });
  });
}
