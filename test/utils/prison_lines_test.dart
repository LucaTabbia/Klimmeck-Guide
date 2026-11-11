import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/prison_lines.dart';

void main() {
  group('prisonReleaseLine', () {
    test('appends the remaining time in the «fra …» form of the potion line '
        '(quick 261110-cgd)', () {
      expect(
        prisonReleaseLine(const Duration(hours: 9, minutes: 12)),
        'Sei in prigione: uscirai fra 9 h 12 min',
      );
    });

    test('without a remaining time it is the plain prison line '
        '(quick 261110-cgd)', () {
      expect(prisonReleaseLine(null), 'Sei in prigione');
      expect(prisonReleaseLine(Duration.zero), 'Sei in prigione');
    });
  });

  group('prisonMarkerLine', () {
    test('tells how long the prison lasts over the pawn', () {
      expect(
        prisonMarkerLine(const Duration(hours: 9, minutes: 12)),
        'In prigione per: 9 h 12 min',
      );
    });
  });
}
