import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';

void main() {
  test('challengeFor matches the RFC 7636 appendix B vector', () {
    expect(
      LoginChallenge.challengeFor(
        'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      ),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  group('generate', () {
    test('produces a 43 char unreserved-charset verifier without padding', () {
      final challenge = LoginChallenge.generate();

      expect(challenge.codeVerifier.length, 43);
      expect(
        challenge.codeVerifier,
        matches(RegExp(r'^[A-Za-z0-9\-._~]{43,128}$')),
      );
      expect(challenge.codeVerifier, isNot(contains('=')));
    });

    test('derives the challenge from the verifier', () {
      final challenge = LoginChallenge.generate();

      expect(
        challenge.codeChallenge,
        LoginChallenge.challengeFor(challenge.codeVerifier),
      );
    });

    test('is random by default', () {
      expect(
        LoginChallenge.generate().codeVerifier,
        isNot(LoginChallenge.generate().codeVerifier),
      );
    });

    test('is deterministic with an injected random', () {
      expect(
        LoginChallenge.generate(random: Random(42)).codeVerifier,
        LoginChallenge.generate(random: Random(42)).codeVerifier,
      );
    });

    test('toString never leaks the verifier', () {
      final challenge = LoginChallenge.generate();

      expect(challenge.toString(), isNot(contains(challenge.codeVerifier)));
    });
  });
}
