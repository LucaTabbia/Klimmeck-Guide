import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

// Runs in its own isolate: dotenv is never loaded here, so the getters must
// fall back to the build-time defaults instead of throwing.
void main() {
  test('EnvConfig backend URLs survive an uninitialised dotenv', () {
    expect(EnvConfig.baseUrl, 'http://192.168.0.20:3000/');
    expect(EnvConfig.graphqlHttpUrl, 'http://192.168.0.20:3000/api/graphql');
    expect(EnvConfig.graphqlWsUrl, 'ws://192.168.0.20:3000/api/graphql');
    expect(EnvConfig.devAuthEnabled, isFalse);
  });
}
