import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directory il cui codice registra solo tramite `appLog` (D-03c).
const List<String> _routedRoots = [
  'lib/repository/services/auth',
  'lib/repository/services/graphql',
  'lib/repository/services/rest',
  'lib/repository/storage',
  'lib/repository/services/sync',
  'lib/repository/cache',
];

const String _appLogPath = 'lib/utils/app_log.dart';

final RegExp _directLogCall = RegExp(
  r'(^|[^A-Za-z_])(debugPrint|print)\(|developer\.log\(',
);

Iterable<File> _dartFilesUnder(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) => file.path != _appLogPath);

List<String> _directLogCallsUnder(String root) {
  final sites = <String>[];
  for (final file in _dartFilesUnder(root)) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (_directLogCall.hasMatch(lines[index])) {
        sites.add('${file.path}:${index + 1}');
      }
    }
  }
  return sites;
}

void main() {
  for (final root in _routedRoots) {
    test('no direct log call under $root (D-03)', () {
      final sites = _directLogCallsUnder(root);
      expect(sites, isEmpty, reason: 'route through appLog: $sites');
    });
  }
}
