import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

import 'dev_auth_env.dart';

void main() {
  group('loadTestEnv', () {
    test('installs the dev values for the current test', () async {
      await loadTestEnv(accessToken: 'scoped-token');

      expect(dotenv.env['DEV_AUTH_ACCESS_TOKEN'], 'scoped-token');
      expect(EnvConfig.devAuthEnabled, isTrue);
    });

    test('leaves no dev value in dotenv for the next test', () {
      expect(!dotenv.isInitialized || dotenv.env.isEmpty, isTrue);
    });
  });
}
