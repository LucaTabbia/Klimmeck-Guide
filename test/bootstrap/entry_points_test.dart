import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Marcatori del bypass dev che il grafo di produzione non deve mai contenere.
const List<String> _devMarkers = [
  'flutter_dotenv',
  'DevAuthTokenService',
  'dev_auth',
  'DEV_AUTH_',
];

const String _bootstrapDir = 'lib/bootstrap';
const String _devCompositionFile = 'lib/bootstrap/dev_auth_composition.dart';

List<String> _bootstrapFiles() =>
    Directory(_bootstrapDir)
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList()
      ..sort();

/// Ogni file di `lib/bootstrap/` tranne la composizione dev: un file nuovo
/// entra nel controllo senza doverlo elencare.
List<String> _sharedCompositionFiles() =>
    _bootstrapFiles().where((path) => path != _devCompositionFile).toList();

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
      for (final path in _sharedCompositionFiles()) ..._devMarkersIn(path),
    ];

    expect(
      _sharedCompositionFiles(),
      contains('lib/bootstrap/app_bootstrap.dart'),
    );
    expect(violations, isEmpty);
  });

  test('lib/bootstrap holds exactly one dev file, the dev composition '
      '(D-01)', () {
    final devFiles = [
      for (final path in _bootstrapFiles())
        if (_devMarkersIn(path).isNotEmpty) path,
    ];

    expect(devFiles, [_devCompositionFile]);
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

  test('bootstrapApp runs the secure-transport blocker before push and any '
      'client (D-03)', () {
    final source = _source('lib/bootstrap/app_bootstrap.dart');
    final blocker = source.indexOf(
      'secureTransportBlocker(isRelease: isRelease)',
    );
    final push = source.indexOf('bootstrapPush()');
    final authApi = source.indexOf('GraphQlBackendAuthApi.forEndpoint');

    expect(blocker, isNonNegative);
    expect(push, isNonNegative);
    expect(authApi, isNonNegative);
    expect(blocker, lessThan(push));
    expect(blocker, lessThan(authApi));
    expect(source, contains('return runApp(blocker)'));
  });

  test('env_config no longer imports flutter_dotenv (D-01)', () {
    expect(
      _source('lib/config/env_config.dart'),
      isNot(contains('flutter_dotenv')),
    );
  });
}
