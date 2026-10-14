import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/portrait_column.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/test_app.dart';

void main() {
  Widget build({
    String? portraitPath,
    PortraitPickFailure? pickFailure,
    bool enabled = true,
    ValueChanged<PortraitSource>? onPick,
    VoidCallback? onRemove,
    double width = 220,
  }) => buildTestApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: PortraitColumn(
          portraitPath: portraitPath,
          pickFailure: pickFailure,
          enabled: enabled,
          onPick: onPick ?? (_) {},
          onRemove: onRemove ?? () {},
        ),
      ),
    ),
  );

  CharacterPortrait portrait(WidgetTester tester) =>
      tester.widget<CharacterPortrait>(find.byType(CharacterPortrait));

  testWidgets('without a portrait shows the silhouette and no Rimuovi', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(build());

    expect(portrait(tester).localFilePath, isNull);
    expect(find.text('Galleria'), findsOneWidget);
    expect(find.text('Fotocamera'), findsOneWidget);
    expect(find.text('Rimuovi'), findsNothing);
  });

  testWidgets('with a portrait passes the path and offers Rimuovi', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(build(portraitPath: '/tmp/p.jpg'));

    expect(portrait(tester).localFilePath, '/tmp/p.jpg');
    expect(find.text('Rimuovi'), findsOneWidget);
  });

  testWidgets('buttons report the pick source and the removal', (tester) async {
    useLandscapePhone(tester);
    final picked = <PortraitSource>[];
    var removed = 0;
    await tester.pumpWidget(
      build(
        portraitPath: '/tmp/p.jpg',
        onPick: picked.add,
        onRemove: () => removed++,
      ),
    );

    await tester.tap(find.text('Galleria'));
    await tester.tap(find.text('Fotocamera'));
    await tester.ensureVisible(find.text('Rimuovi'));
    await tester.tap(find.text('Rimuovi'));

    expect(picked, [PortraitSource.gallery, PortraitSource.camera]);
    expect(removed, 1);
  });

  testWidgets('shows the pick failure message', (tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      build(pickFailure: PortraitPickFailure.permissionDenied),
    );

    expect(
      find.text(
        "Permesso negato: abilita l'accesso a foto e fotocamera dalle impostazioni",
      ),
      findsOneWidget,
    );
  });

  testWidgets('every action button meets the 44x44 tap target', (tester) async {
    useLandscapePhone(tester);
    // Wide enough for one-line labels with the wide test font: the height
    // then measures the hit area, not a wrapped label.
    await tester.pumpWidget(build(portraitPath: '/tmp/p.jpg', width: 700));

    for (final label in ['Galleria', 'Fotocamera', 'Rimuovi']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((widget) => widget is TextButton),
      );
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(44), reason: '$label height');
      expect(size.width, greaterThanOrEqualTo(44), reason: '$label width');
    }
  });

  testWidgets('disables every button when not enabled', (tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(build(portraitPath: '/tmp/p.jpg', enabled: false));

    final buttons = tester.widgetList<TextButton>(
      find.byWidgetPredicate((widget) => widget is TextButton),
    );
    expect(buttons, hasLength(3));
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });
}
