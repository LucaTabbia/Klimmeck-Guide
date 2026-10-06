import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

import '../helpers/fixtures/dev_auth_env.dart';

void main() {
  group('EnvConfig.devAuthEnabled', () {
    test('is true for "true" in any case', () async {
      await loadTestEnv(devAuthEnabled: 'TRUE');

      expect(EnvConfig.devAuthEnabled, isTrue);
    });

    test('tolerates whitespace around the value', () async {
      await loadTestEnv(devAuthEnabled: '" true "');

      expect(EnvConfig.devAuthEnabled, isTrue);
    });

    test('is false for any other value', () async {
      await loadTestEnv(devAuthEnabled: 'yes');

      expect(EnvConfig.devAuthEnabled, isFalse);
    });
  });
}
