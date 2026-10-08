import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

void main() {
  group('EnvConfig backend URLs', () {
    test('come from .env when the keys are set', () {
      dotenv.loadFromString(
        envString: '''
BASE_URL=http://localhost:3000/
GRAPHQL_HTTP_URL=http://localhost:3000/api/graphql
GRAPHQL_WS_URL=ws://localhost:3000/api/graphql
''',
      );

      expect(EnvConfig.baseUrl, 'http://localhost:3000/');
      expect(EnvConfig.graphqlHttpUrl, 'http://localhost:3000/api/graphql');
      expect(EnvConfig.graphqlWsUrl, 'ws://localhost:3000/api/graphql');
    });

    test('ignore surrounding whitespace in .env values', () {
      dotenv.loadFromString(envString: 'BASE_URL="  http://localhost:3000/  "');

      expect(EnvConfig.baseUrl, 'http://localhost:3000/');
    });

    test('fall back to the build-time defaults when the keys are absent', () {
      dotenv.loadFromString(envString: 'DEV_AUTH_ENABLED=false');

      expect(EnvConfig.baseUrl, 'http://192.168.0.20:3000/');
      expect(EnvConfig.graphqlHttpUrl, 'http://192.168.0.20:3000/api/graphql');
      expect(EnvConfig.graphqlWsUrl, 'ws://192.168.0.20:3000/api/graphql');
    });

    test('treat an empty .env value as absent', () {
      dotenv.loadFromString(envString: 'GRAPHQL_WS_URL=');

      expect(EnvConfig.graphqlWsUrl, 'ws://192.168.0.20:3000/api/graphql');
    });
  });
}
