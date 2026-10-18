import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_background.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/test_app.dart';

void main() {
  const labels = [
    'Mappa',
    'Profilo',
    'Diario',
    'Libreria',
    'Bacheca',
    'Negozio',
    'Impostazioni',
    'Chiudi il menù',
  ];

  Future<List<int>> pumpOverlay(WidgetTester tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      buildTestApp(
        home: MenuBackground(
          selectedIndex: 0,
          onTap: taps.add,
          opacityAnimation: const AlwaysStoppedAnimation(1.0),
        ),
      ),
    );
    await tester.pump();
    return taps;
  }

  void useSmallLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(2001, 1125);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows the seven labels and the close label at 780x360', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await pumpOverlay(tester);

    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a label reports its page index', (tester) async {
    useLandscapePhone(tester);
    final taps = await pumpOverlay(tester);

    await tester.tap(find.text('Impostazioni'));
    await tester.tap(find.text('Mappa'));
    await tester.tap(find.text('Bacheca'));

    expect(taps, [6, 0, 4]);
  });

  testWidgets('the Mappa cell is twice as tall as the Profilo cell', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await pumpOverlay(tester);

    final mappa = tester.getSize(find.byKey(const ValueKey('satchel-cell-0')));
    final profilo = tester.getSize(
      find.byKey(const ValueKey('satchel-cell-1')),
    );
    expect(mappa.height, 2 * profilo.height);
  });

  testWidgets('the Impostazioni cell sits at the bottom-right of the grid', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await pumpOverlay(tester);

    final topLeft = tester.getTopLeft(
      find.byKey(const ValueKey('satchel-cell-6')),
    );
    expect(
      topLeft,
      Offset(
        SatchelLayout.closeColumnWidth + 3 * SatchelLayout.cellWidth(780),
        180,
      ),
    );
  });

  testWidgets('fits a 667x375 screen without overflow', (tester) async {
    useSmallLandscape(tester);
    await pumpOverlay(tester);

    expect(tester.takeException(), isNull);
    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    final right = tester.getBottomRight(
      find.byKey(const ValueKey('satchel-cell-6')),
    );
    expect(right.dx, lessThanOrEqualTo(667));
  });
}
