import 'dart:convert';

import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/user.dart';

import 'auth_fixtures.dart';

final DateTime testNow = DateTime.utc(2026, 10, 6, 12);
const Duration testAccessTokenLifetime = Duration(minutes: 15);

String _segment(Map<String, Object?> json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

/// JWT fittizio (firma finta): solo per lo scheduling, il backend è l'unico che verifica.
String buildTestJwt({
  DateTime? issuedAt,
  Duration lifetime = testAccessTokenLifetime,
  String subject = testUserId,
}) {
  final iat = (issuedAt ?? testNow).millisecondsSinceEpoch ~/ 1000;
  final header = _segment({'alg': 'HS256', 'typ': 'JWT'});
  final payload = _segment({
    'sub': subject,
    'iat': iat,
    'exp': iat + lifetime.inSeconds,
  });
  return '$header.$payload.signature';
}

AuthSession buildAuthSession({
  String? accessToken,
  String refreshToken = 'refresh-token-1',
  DateTime? expiresAt,
  User? user,
}) => AuthSession(
  accessToken: accessToken ?? buildTestJwt(),
  accessTokenExpiresAt: expiresAt ?? testNow.add(testAccessTokenLifetime),
  refreshToken: refreshToken,
  user: user ?? buildTestUser(),
);

Map<String, dynamic> authSessionJson({
  String accessToken = 'a',
  String refreshToken = 'r',
  String expiresAt = '2026-10-06T12:15:00.000Z',
  String userId = testUserId,
}) => {
  'accessToken': accessToken,
  'accessTokenExpiresAt': expiresAt,
  'refreshToken': refreshToken,
  'user': {
    'id': userId,
    'twitchId': testTwitchId,
    'twitchPoints': 0,
    'role': 'adventurer',
    'currentCharacter': null,
  },
};
