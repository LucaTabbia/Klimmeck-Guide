import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/login_callback.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';

void main() {
  group('parseLoginCallback', () {
    test('returns the ticket', () {
      expect(
        parseLoginCallback('klimmeck://auth?ticket=abc'),
        const LoginTicketReceived('abc'),
      );
    });

    test('ticket wins over error', () {
      expect(
        parseLoginCallback('klimmeck://auth?ticket=abc&error=x'),
        const LoginTicketReceived('abc'),
      );
    });

    test('maps access_denied to user denial', () {
      expect(
        parseLoginCallback('klimmeck://auth?error=access_denied'),
        const LoginDeniedByUser(),
      );
    });

    test('keeps backend error codes opaque', () {
      expect(
        parseLoginCallback('klimmeck://auth?error=twitch_not_configured'),
        const LoginRejectedByBackend(twitchNotConfiguredError),
      );
      expect(
        parseLoginCallback('klimmeck://auth?error=invalid_state'),
        const LoginRejectedByBackend('invalid_state'),
      );
    });

    test('never throws on malformed input', () {
      const invalid = LoginRejectedByBackend('invalid_callback');

      expect(parseLoginCallback('klimmeck://auth'), invalid);
      expect(parseLoginCallback('klimmeck://auth?ticket='), invalid);
      expect(parseLoginCallback('not a url ::'), invalid);
    });

    test('rejects a foreign scheme', () {
      expect(
        parseLoginCallback('https://evil.example/auth?ticket=abc'),
        const LoginRejectedByBackend('invalid_callback'),
      );
    });

    test('ticket toString does not leak the ticket', () {
      expect(
        const LoginTicketReceived('secret-ticket').toString(),
        isNot(contains('secret-ticket')),
      );
    });
  });

  group('LoginException', () {
    test('compare by value', () {
      expect(const LoginCancelledException(), const LoginCancelledException());
      expect(
        const LoginUnavailableException(),
        const LoginUnavailableException(),
      );
      expect(const LoginFailedException('x'), const LoginFailedException('x'));
      expect(
        const LoginFailedException('x'),
        isNot(const LoginFailedException('y')),
      );
      expect(const LoginFailedException('x').code, 'x');
    });
  });
}
