import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

void main() {
  const landscape = Size(780, 360);
  final entries = SatchelLayout.entries;
  SatchelEntry byLabel(String label) =>
      entries.firstWhere((entry) => entry.label == label);

  test('exposes seven entries with page indices 0..6 in order', () {
    expect(entries.map((e) => e.pageIndex), [0, 1, 2, 3, 4, 5, 6]);
    expect(entries.map((e) => e.label), [
      'Mappa',
      'Profilo',
      'Diario',
      'Libreria',
      'Bacheca',
      'Negozio',
      'Impostazioni',
    ]);
  });

  test('places Mappa on two rows and the others on a 2x3 grid', () {
    expect(byLabel('Mappa').column, 0);
    expect(byLabel('Mappa').row, 0);
    expect(byLabel('Mappa').rowSpan, 2);
    for (final entry in entries.skip(1)) {
      expect(entry.rowSpan, 1);
    }
    expect(['Profilo', 'Diario', 'Libreria'].map((l) => byLabel(l).row), [
      0,
      0,
      0,
    ]);
    expect(['Profilo', 'Diario', 'Libreria'].map((l) => byLabel(l).column), [
      1,
      2,
      3,
    ]);
    expect(['Bacheca', 'Negozio', 'Impostazioni'].map((l) => byLabel(l).row), [
      1,
      1,
      1,
    ]);
    expect(
      ['Bacheca', 'Negozio', 'Impostazioni'].map((l) => byLabel(l).column),
      [1, 2, 3],
    );
  });

  test('covers every cell of the 4x2 grid exactly once', () {
    final covered = <(int, int)>[];
    for (final entry in entries) {
      for (var r = entry.row; r < entry.row + entry.rowSpan; r++) {
        covered.add((entry.column, r));
      }
    }
    final expected = {
      for (var c = 0; c < SatchelLayout.columns; c++)
        for (var r = 0; r < SatchelLayout.rows; r++) (c, r),
    };
    expect(covered.length, 8);
    expect(covered.toSet(), expected);
  });

  test('maps every entry to its asset', () {
    expect(entries.map((e) => e.assetPath), [
      CloudinaryAssets.map,
      CloudinaryAssets.mirror,
      CloudinaryAssets.journal,
      CloudinaryAssets.library,
      CloudinaryAssets.board,
      CloudinaryAssets.shop,
      CloudinaryAssets.settings,
    ]);
    expect(CloudinaryAssets.settings, 'v1792150334/settings_linee3.svg');
  });

  test('cellWidth shrinks on narrow screens and caps at 152', () {
    expect(SatchelLayout.cellWidth(780), 152);
    expect(SatchelLayout.cellWidth(1200), 152);
    expect(SatchelLayout.cellWidth(667), 128.75);
    expect(SatchelLayout.cellWidth(552), 100);
  });

  test('centerOf returns the centre of the entry cell', () {
    expect(
      SatchelLayout.centerOf(byLabel('Impostazioni'), landscape),
      const Offset(684, 270),
    );
    expect(
      SatchelLayout.centerOf(byLabel('Mappa'), landscape),
      const Offset(228, 180),
    );
  });

  test('flightEnd keeps the legacy vertical landing points', () {
    expect(
      SatchelLayout.flightEnd(byLabel('Profilo'), landscape, 100),
      const Offset(330, -220),
    );
    expect(
      SatchelLayout.flightEnd(byLabel('Bacheca'), landscape, 100),
      const Offset(330, -40),
    );
    expect(
      SatchelLayout.flightEnd(byLabel('Mappa'), landscape, 100),
      const Offset(178, -130),
    );
    expect(
      SatchelLayout.flightEnd(byLabel('Impostazioni'), landscape, 100),
      const Offset(634, -40),
    );
  });

  test('the last column fits a 667x375 screen', () {
    const small = Size(667, 375);
    final halfCell = SatchelLayout.cellWidth(small.width) / 2;
    for (final entry in entries) {
      expect(
        SatchelLayout.centerOf(entry, small).dx + halfCell,
        lessThanOrEqualTo(small.width),
      );
    }
  });
}
