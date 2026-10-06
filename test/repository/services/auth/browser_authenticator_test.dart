import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';

void main() {
  group('mapBrowserAuthError', () {
    test('maps CANCELED to cancellation', () {
      expect(
        mapBrowserAuthError(PlatformException(code: 'CANCELED')),
        const BrowserAuthCancelled(),
      );
    });

    test('maps any other code to a failure carrying the code', () {
      expect(
        mapBrowserAuthError(PlatformException(code: 'EUNKNOWN')),
        const BrowserAuthFailure('EUNKNOWN'),
      );
      expect(
        mapBrowserAuthError(PlatformException(code: 'NO_BROWSER')),
        const BrowserAuthFailure('NO_BROWSER'),
      );
    });
  });

  test('browser exceptions compare by value', () {
    expect(const BrowserAuthCancelled(), const BrowserAuthCancelled());
    expect(const BrowserAuthFailure('a'), isNot(const BrowserAuthFailure('b')));
  });
}
