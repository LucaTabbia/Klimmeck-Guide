import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

void main() {
  group('EnvConfig backend URLs', () {
    tearDown(EnvConfig.resetRuntimeOverrides);

    test('come from the runtime overrides when the keys are set (D-02)', () {
      EnvConfig.installRuntimeOverrides({
        'BASE_URL': 'http://localhost:3000/',
        'GRAPHQL_HTTP_URL': 'http://localhost:3000/api/graphql',
        'GRAPHQL_WS_URL': 'ws://localhost:3000/api/graphql',
      });

      expect(EnvConfig.baseUrl, 'http://localhost:3000/');
      expect(EnvConfig.graphqlHttpUrl, 'http://localhost:3000/api/graphql');
      expect(EnvConfig.graphqlWsUrl, 'ws://localhost:3000/api/graphql');
    });

    test('ignore surrounding whitespace in the override values (D-02)', () {
      EnvConfig.installRuntimeOverrides({
        'BASE_URL': '  http://localhost:3000/  ',
      });

      expect(EnvConfig.baseUrl, 'http://localhost:3000/');
    });

    test(
      'fall back to the build-time defaults when the keys are absent (D-02)',
      () {
        EnvConfig.installRuntimeOverrides({'DEV_AUTH_ENABLED': 'false'});

        expect(EnvConfig.baseUrl, 'http://192.168.0.20:3000/');
        expect(
          EnvConfig.graphqlHttpUrl,
          'http://192.168.0.20:3000/api/graphql',
        );
        expect(EnvConfig.graphqlWsUrl, 'ws://192.168.0.20:3000/api/graphql');
      },
    );

    test('ignore empty override values (D-02)', () {
      EnvConfig.installRuntimeOverrides({'BASE_URL': '   '});

      expect(EnvConfig.baseUrl, 'http://192.168.0.20:3000/');
    });

    test('resetRuntimeOverrides restores the defaults (D-02)', () {
      EnvConfig.installRuntimeOverrides({
        'BASE_URL': 'http://localhost:3000/',
        'GRAPHQL_HTTP_URL': 'http://localhost:3000/api/graphql',
        'GRAPHQL_WS_URL': 'ws://localhost:3000/api/graphql',
      });

      EnvConfig.resetRuntimeOverrides();

      expect(EnvConfig.baseUrl, 'http://192.168.0.20:3000/');
      expect(EnvConfig.graphqlHttpUrl, 'http://192.168.0.20:3000/api/graphql');
      expect(EnvConfig.graphqlWsUrl, 'ws://192.168.0.20:3000/api/graphql');
    });

    test('the installed overrides cannot be modified afterwards (D-02)', () {
      final values = {'BASE_URL': 'http://localhost:3000/'};
      EnvConfig.installRuntimeOverrides(values);

      values['BASE_URL'] = 'http://elsewhere:3000/';

      expect(EnvConfig.baseUrl, 'http://localhost:3000/');
    });
  });
}
