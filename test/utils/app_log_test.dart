import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

void main() {
  test('forwards the message to the sink outside release (D-03)', () {
    final lines = <String>[];

    appLogWith('hello', isRelease: false, sink: lines.add);

    expect(lines, ['hello']);
  });

  test('stays silent in release (D-03)', () {
    final lines = <String>[];

    appLogWith('hello', isRelease: true, sink: lines.add);

    expect(lines, isEmpty);
  });

  test('appLog writes through debugPrint in tests (D-03)', () {
    final captured = <String?>[];
    final original = debugPrint;
    addTearDown(() => debugPrint = original);
    debugPrint = (String? message, {int? wrapWidth}) => captured.add(message);

    appLog('x');

    expect(captured, ['x']);
  });
}
