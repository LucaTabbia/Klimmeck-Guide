import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/config/insecure_transport_error.dart';

const Map<String, String> _cleartextUrls = {
  'BASE_URL': 'http://h/',
  'GRAPHQL_HTTP_URL': 'http://h/api/graphql',
  'GRAPHQL_WS_URL': 'ws://h/api/graphql',
};

const Map<String, String> _secureUrls = {
  'BASE_URL': 'https://h/',
  'GRAPHQL_HTTP_URL': 'https://h/api/graphql',
  'GRAPHQL_WS_URL': 'wss://h/api/graphql',
};

Matcher _offending(List<String> keys) => isA<InsecureTransportError>().having(
  (error) => error.offendingKeys,
  'offendingKeys',
  keys,
);

void main() {
  group('EnvConfig.requireSecureTransport', () {
    tearDown(EnvConfig.resetRuntimeOverrides);

    test(
      'release refuses cleartext backend URLs and names the keys (D-03)',
      () {
        EnvConfig.installRuntimeOverrides(_cleartextUrls);

        expect(
          () => EnvConfig.requireSecureTransport(isRelease: true),
          throwsA(
            _offending(['BASE_URL', 'GRAPHQL_HTTP_URL', 'GRAPHQL_WS_URL']),
          ),
        );
      },
    );

    test('release accepts https and wss (D-03)', () {
      EnvConfig.installRuntimeOverrides(_secureUrls);

      expect(
        () => EnvConfig.requireSecureTransport(isRelease: true),
        returnsNormally,
      );
    });

    test('release names only the cleartext key (D-03)', () {
      EnvConfig.installRuntimeOverrides({
        ..._secureUrls,
        'GRAPHQL_WS_URL': 'ws://h/api/graphql',
      });

      expect(
        () => EnvConfig.requireSecureTransport(isRelease: true),
        throwsA(_offending(['GRAPHQL_WS_URL'])),
      );
    });

    test(
      'a wss scheme on the HTTP URL or https on the WS URL is refused (D-03)',
      () {
        EnvConfig.installRuntimeOverrides({
          ..._secureUrls,
          'GRAPHQL_HTTP_URL': 'wss://h/api/graphql',
          'GRAPHQL_WS_URL': 'https://h/api/graphql',
        });

        expect(
          () => EnvConfig.requireSecureTransport(isRelease: true),
          throwsA(_offending(['GRAPHQL_HTTP_URL', 'GRAPHQL_WS_URL'])),
        );
      },
    );

    test('the built-in defaults are refused in release (D-03)', () {
      expect(
        () => EnvConfig.requireSecureTransport(isRelease: true),
        throwsA(_offending(['BASE_URL', 'GRAPHQL_HTTP_URL', 'GRAPHQL_WS_URL'])),
      );
    });

    test('debug only logs the cleartext URLs (D-03)', () {
      final captured = <String?>[];
      final originalDebugPrint = debugPrint;
      addTearDown(() => debugPrint = originalDebugPrint);
      debugPrint = (String? message, {int? wrapWidth}) => captured.add(message);
      EnvConfig.installRuntimeOverrides(_cleartextUrls);

      expect(
        () => EnvConfig.requireSecureTransport(isRelease: false),
        returnsNormally,
      );
      expect(captured, hasLength(1));
      expect(captured.single, contains('GRAPHQL_WS_URL'));
      expect(captured.single, isNot(contains('http://h')));
    });

    test('the error never carries a URL (D-03)', () {
      expect(
        InsecureTransportError(['BASE_URL']).toString(),
        'InsecureTransportError(BASE_URL)',
      );
    });
  });
}
