import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/test_app.dart';

Future<void> pumpCard(WidgetTester tester, LoreCard card) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final Lore andogan = Lore.fromJson(
    loreJson(id: 'lore-andogan', name: 'Andogan'),
  );

  testWidgets('a new entry carries the «Nuovo» bookmark (D-07)', (
    tester,
  ) async {
    await pumpCard(tester, LoreCard(lore: andogan, isNew: true));

    expect(LoreCard.newMarkLabel, 'Nuovo');
    expect(find.byKey(LoreCard.newMarkKey), findsOneWidget);
    expect(find.text('Nuovo'), findsOneWidget);
  });

  testWidgets('an entry already seen carries no bookmark (D-07)', (
    tester,
  ) async {
    await pumpCard(tester, LoreCard(lore: andogan));

    expect(find.byKey(LoreCard.newMarkKey), findsNothing);
    expect(find.text('Nuovo'), findsNothing);
  });

  testWidgets('the bookmark takes the ink of its book (D-07)', (tester) async {
    await pumpCard(
      tester,
      LoreCard(
        lore: andogan,
        isNew: true,
        newMarkInk: KlimmeckGuideTheme.healGreen,
      ),
    );

    final mark = find.descendant(
      of: find.byKey(LoreCard.newMarkKey),
      matching: find.byType(DecoratedBox),
      matchRoot: true,
    );
    final decoration =
        tester.widget<DecoratedBox>(mark.first).decoration as BoxDecoration;
    expect(decoration.color, KlimmeckGuideTheme.healGreen);
  });

  testWidgets('a lore without description still shows its name (D-06)', (
    tester,
  ) async {
    await pumpCard(
      tester,
      LoreCard(
        lore: Lore.fromJson(
          loreJson(id: 'lore-bosa', name: 'Bosa', description: null),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Bosa'), findsOneWidget);
  });
}
