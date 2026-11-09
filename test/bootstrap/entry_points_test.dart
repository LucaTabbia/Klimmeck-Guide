import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Marcatori del bypass dev che il grafo di produzione non deve mai contenere.
const List<String> _devMarkers = [
  'flutter_dotenv',
  'DevAuthTokenService',
  'dev_auth',
  'DEV_AUTH_',
];

const List<String> _sharedCompositionFiles = [
  'lib/bootstrap/app_bootstrap.dart',
  'lib/bootstrap/session_auth_composition.dart',
  'lib/bootstrap/auth_composition.dart',
  'lib/bootstrap/klimmeck_guide_app.dart',
  'lib/bootstrap/insecure_transport_screen.dart',
];

String _source(String path) => File(path).readAsStringSync();

List<String> _devMarkersIn(String path) {
  final source = _source(path);
  return [
    for (final marker in _devMarkers)
      if (source.contains(marker)) '$path mentions $marker',
  ];
}

void main() {
  test(
    'the production entry point only boots the session composition (D-01)',
    () {
      expect(
        _source('lib/main.dart'),
        contains('bootstrapApp(buildAuth: buildSessionAuthComposition)'),
      );
      expect(_devMarkersIn('lib/main.dart'), isEmpty);
    },
  );

  test('the shared composition files never mention the dev bypass (D-01)', () {
    final violations = [
      for (final path in _sharedCompositionFiles) ..._devMarkersIn(path),
    ];

    expect(violations, isEmpty);
  });

  test('the auth barrel no longer exports the dev bypass (D-01)', () {
    expect(
      _source('lib/repository/services/auth/auth.dart'),
      isNot(contains('dev_auth_token_service.dart')),
    );
  });

  test('the dev entry point checks the flavor before loading .env (D-16)', () {
    final source = _source('lib/main_dev.dart');
    final flavorAssert = source.indexOf("assert(appFlavor == 'dev'");
    final dotenvLoad = source.indexOf('dotenv.load(');

    expect(flavorAssert, isNonNegative);
    expect(dotenvLoad, isNonNegative);
    expect(flavorAssert, lessThan(dotenvLoad));
  });

  test('env_config no longer imports flutter_dotenv (D-01)', () {
    expect(
      _source('lib/config/env_config.dart'),
      isNot(contains('flutter_dotenv')),
    );
  });
}
