import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _pushDir = 'lib/repository/services/push';
const String _backgroundHandler = '$_pushDir/push_background_handler.dart';
const String _bootstrap = '$_pushDir/push_bootstrap.dart';

/// Unici file app autorizzati a importare ciascun plugin push (D-19).
const Map<String, Set<String>> _allowedImporters = {
  'package:firebase_messaging/': {
    '$_pushDir/firebase_push_messaging.dart',
    _backgroundHandler,
    _bootstrap,
  },
  'package:firebase_core/': {_bootstrap},
  'package:flutter_local_notifications/': {
    '$_pushDir/flutter_local_notifications_adapter.dart',
  },
  'package:permission_handler/': {
    '$_pushDir/permission_handler_notification_permission.dart',
  },
  'package:url_launcher/': {'$_pushDir/url_launcher_link_opener.dart'},
};

/// File che importano plugin: i test non li toccano mai.
const List<String> _pluginBackedFiles = [
  'firebase_push_messaging.dart',
  'flutter_local_notifications_adapter.dart',
  'permission_handler_notification_permission.dart',
  'url_launcher_link_opener.dart',
  'push_background_handler.dart',
  'push_bootstrap.dart',
];

const String _thisFile =
    'test/repository/services/push/push_boundaries_test.dart';

const String _permissionGate = '$_pushDir/notification_permission_gate.dart';

/// Unico chiamante del gate: la conferma di viaggio riuscita (Phase 7 D-05).
const String _travelRepository = 'lib/repository/travel_repository.dart';

/// Superfici di Phase 5 che non devono mai mostrare il prompt notifiche (D-10, NOTIF-02).
const List<String> _promptFreeFiles = [
  'lib/main.dart',
  'lib/screens/auth/auth_gate.dart',
  'lib/screens/splash/splash_screen.dart',
];
const String _settingsDir = 'lib/screens/mainScreen/tabs/settings';
const List<String> _promptCalls = [
  'ensureRequested(',
  'Permission.notification',
  '.request()',
];

final RegExp _importDirective = RegExp(r'''^import\s+['"]([^'"]+)['"]''');

Iterable<File> _dartFilesUnder(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

String _normalised(File file) => file.path.replaceAll(r'\', '/');

Iterable<String> _importsOf(File file) => file
    .readAsLinesSync()
    .map((line) => _importDirective.firstMatch(line.trim())?.group(1))
    .whereType<String>();

void main() {
  test('push plugins are imported only by their adapters', () {
    final violations = <String>[
      for (final file in _dartFilesUnder('lib'))
        for (final uri in _importsOf(file))
          for (final entry in _allowedImporters.entries)
            if (uri.startsWith(entry.key) &&
                !entry.value.contains(_normalised(file)))
              '${_normalised(file)} imports $uri',
    ];

    expect(violations, isEmpty);
  });

  test('tests never import push plugins or plugin-backed files', () {
    final violations = <String>[
      for (final file in _dartFilesUnder('test'))
        if (_normalised(file) != _thisFile)
          for (final uri in _importsOf(file))
            if (_allowedImporters.keys.any(uri.startsWith) ||
                _pluginBackedFiles.any(uri.endsWith))
              '${_normalised(file)} imports $uri',
    ];

    expect(violations, isEmpty);
  });

  test('the background isolate never initialises Firebase', () {
    final source = File(_backgroundHandler).readAsStringSync();

    expect(source, isNot(contains('initializeApp')));
  });

  group('permission prompt (NOTIF-02)', () {
    test('only the travel repository calls ensureRequested', () {
      final callers = <String>[
        for (final file in _dartFilesUnder('lib'))
          if (_normalised(file) != _permissionGate &&
              file.readAsStringSync().contains('ensureRequested('))
            _normalised(file),
      ];

      expect(callers, [_travelRepository]);
    });

    test('Phase 5 surfaces never reach the prompt', () {
      final surfaces = <String>[
        ..._promptFreeFiles,
        for (final file in _dartFilesUnder(_settingsDir)) _normalised(file),
      ];
      final violations = <String>[
        for (final path in surfaces)
          for (final call in _promptCalls)
            if (File(path).readAsStringSync().contains(call)) '$path: $call',
      ];

      expect(violations, isEmpty);
    });
  });
}
