import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Coppia S256 che lega la tratta app↔backend del login (D-15). Non è Twitch PKCE.
class LoginChallenge {
  const LoginChallenge({
    required this.codeVerifier,
    required this.codeChallenge,
  });

  factory LoginChallenge.generate({Random? random}) {
    final rng = random ?? Random.secure();
    final verifier = _base64UrlNoPadding(
      List<int>.generate(_verifierByteLength, (_) => rng.nextInt(256)),
    );
    return LoginChallenge(
      codeVerifier: verifier,
      codeChallenge: challengeFor(verifier),
    );
  }

  static const int _verifierByteLength = 32; // 32 byte → 43 caratteri base64url

  final String codeVerifier;
  final String codeChallenge;

  static String challengeFor(String codeVerifier) =>
      _base64UrlNoPadding(sha256.convert(ascii.encode(codeVerifier)).bytes);

  static String _base64UrlNoPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  @override
  String toString() => 'LoginChallenge(codeChallenge: $codeChallenge)';
}
