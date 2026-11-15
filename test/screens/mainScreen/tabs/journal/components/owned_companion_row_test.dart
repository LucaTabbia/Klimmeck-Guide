import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/owned_companion_row.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

const double _cardSize = 120;
const String _worg = 'pet-worg';
const Duration _hour = Duration(hours: 1);

OwnedPet _owned({
  String? name,
  int? level,
  int? ownMaxLifePoints,
  int xp = 40,
  num? speedModifier,
  bool isDefeated = false,
  bool? known,
}) => OwnedPet(
  pet: Pet.fromJson(
    petJson(
      id: _worg,
      name: 'Worg',
      maxXp: 300,
      maxLifePoints: 100,
      speedModifier: speedModifier,
      known: known,
    ),
  ),
  xp: xp,
  currentLifePoints: 20,
  name: name,
  level: level,
  ownMaxLifePoints: ownMaxLifePoints,
  isDefeated: isDefeated,
);

Finder _row() => find.byKey(const ValueKey('owned-pet-$_worg'));

Finder _xpLine() => find.byKey(const ValueKey('companion-xp-$_worg'));

Finder _lifeLine() => find.byKey(const ValueKey('companion-life-$_worg'));

Finder _statusLine() => find.byKey(const ValueKey('companion-status-$_worg'));

Finder _potionLine() => find.byKey(const ValueKey('companion-potion-$_worg'));

String? _textOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data;

String? _cardLabelOf(WidgetTester tester, Key key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .data;

void main() {
  late int taps;
  late int longPresses;

  setUp(() {
    taps = 0;
    longPresses = 0;
    seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
    ]);
  });

  Future<void> pump(
    WidgetTester tester, {
    OwnedPet? owned,
    CompanionVitality? vitality,
    Duration? potionWait,
    bool isDisplayed = false,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: OwnedCompanionRow(
            owned: owned ?? _owned(),
            vitality: vitality,
            potionWait: potionWait,
            isDisplayed: isDisplayed,
            isPending: false,
            cardSize: _cardSize,
            onTap: () => taps++,
            onLongPress: () => longPresses++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a resting companion reads «Vita» and «A riposo: in forze fra …» (D-09)',
    (tester) async {
      await pump(
        tester,
        vitality: const CompanionResting(
          life: 40,
          maxLifePoints: 100,
          remaining: _hour,
        ),
      );

      expect(_textOf(tester, _lifeLine()), 'Vita: 40 / 100');
      expect(_textOf(tester, _statusLine()), companionRestingLine(_hour));
    },
  );

  testWidgets(
    'a defeated companion is faded, not tappable and reads «Sconfitto: torna '
    'fra …» (D-02, D-09)',
    (tester) async {
      await pump(
        tester,
        vitality: const CompanionDefeated(
          life: 1,
          maxLifePoints: 100,
          remaining: _hour,
        ),
      );

      expect(_textOf(tester, _statusLine()), companionDefeatedLine(_hour));
      final fade = tester.widget<AnimatedOpacity>(
        find
            .descendant(of: _row(), matching: find.byType(AnimatedOpacity))
            .first,
      );
      expect(fade.opacity, KlimmeckGuideTheme.pendingInkOpacity);

      await tester.tap(_row());
      await tester.pumpAndSettle();

      expect(taps, 0);
    },
  );

  testWidgets(
    'a companion served defeated is not tappable before its vitality is '
    'computed (D-02)',
    (tester) async {
      await pump(tester, owned: _owned(isDefeated: true));

      await tester.tap(_row());
      await tester.pumpAndSettle();

      expect(taps, 0);
    },
  );

  testWidgets('the long press calls onLongPress, also when defeated (D-22)', (
    tester,
  ) async {
    await pump(
      tester,
      vitality: const CompanionDefeated(
        life: 1,
        maxLifePoints: 100,
        remaining: _hour,
      ),
    );

    await tester.longPress(_row());
    await tester.pumpAndSettle();

    expect(longPresses, 1);
    expect(taps, 0);
  });

  testWidgets('the long press opens nothing for a companion whose lore is '
      'not unlocked; the tap still equips (UAT 2026-11-15)', (tester) async {
    await pump(tester, owned: _owned(known: false));

    await tester.longPress(_row());
    await tester.pumpAndSettle();
    await tester.tap(_row());
    await tester.pumpAndSettle();

    expect(longPresses, 0);
    expect(taps, 1);
  });

  testWidgets(
    'the equipped companion shows its life with no countdown (D-04)',
    (tester) async {
      await pump(
        tester,
        isDisplayed: true,
        vitality: const CompanionSteady(life: 20, maxLifePoints: 100),
      );

      expect(_textOf(tester, _lifeLine()), 'Vita: 20 / 100');
      expect(_statusLine(), findsNothing);
      expect(find.text(companionEquippedMark), findsOneWidget);

      await tester.tap(_row());
      await tester.pumpAndSettle();

      expect(taps, 1);
    },
  );

  testWidgets('a named companion reads its name as title and the species below '
      '(D-20)', (tester) async {
    await pump(tester, owned: _owned(name: 'Zanna'));

    final card = tester.widget<CompanionCard>(find.byType(CompanionCard));
    expect(card.name, 'Zanna');
    expect(_cardLabelOf(tester, CompanionCard.titleKeyOf(_worg)), 'Zanna');
    expect(_cardLabelOf(tester, CompanionCard.speciesKeyOf(_worg)), 'Worg');
  });

  testWidgets('a levelled companion reads «Worg · Livello 3» and «Vita: x / '
      '200» with its own max (D-37, D-38)', (tester) async {
    await pump(
      tester,
      owned: _owned(name: 'Zanna', level: 3, ownMaxLifePoints: 200),
      vitality: const CompanionSteady(life: 150, maxLifePoints: 200),
    );

    expect(
      _cardLabelOf(tester, CompanionCard.speciesKeyOf(_worg)),
      'Worg · Livello 3',
    );
    expect(_textOf(tester, _lifeLine()), 'Vita: 150 / 200');
  });

  testWidgets('an unnamed levelled companion reads «Livello 3» under the '
      'species (D-37)', (tester) async {
    await pump(tester, owned: _owned(level: 3));

    expect(_cardLabelOf(tester, CompanionCard.titleKeyOf(_worg)), 'Worg');
    expect(
      _cardLabelOf(tester, CompanionCard.speciesKeyOf(_worg)),
      'Livello 3',
    );
  });

  testWidgets('the companion potion wait shows on its parchment (D-05, D-32)', (
    tester,
  ) async {
    await pump(
      tester,
      vitality: const CompanionSteady(life: 20, maxLifePoints: 100),
      potionWait: _hour,
    );

    expect(_textOf(tester, _potionLine()), companionPotionWaitLine(_hour));
  });

  testWidgets('the lines read in order «Al tuo fianco», «Esperienza», «Vita», '
      'status, «Pozione» (D-09)', (tester) async {
    await pump(
      tester,
      isDisplayed: true,
      vitality: const CompanionResting(
        life: 40,
        maxLifePoints: 100,
        remaining: _hour,
      ),
      potionWait: _hour,
    );

    final lines = [
      find.text(companionEquippedMark),
      _xpLine(),
      _lifeLine(),
      _statusLine(),
      _potionLine(),
    ];
    final tops = [for (final line in lines) tester.getTopLeft(line).dy];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]));
    }
  });

  testWidgets('the card keeps the speed of a mount (D-10)', (tester) async {
    await pump(
      tester,
      owned: _owned(speedModifier: 2),
      vitality: const CompanionSteady(life: 20, maxLifePoints: 100),
    );

    expect(
      find.descendant(
        of: find.byType(CompanionCard),
        matching: find.text('Velocità ×2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no life line without a vitality (D-09)', (tester) async {
    await pump(tester);

    expect(_xpLine(), findsOneWidget);
    expect(_lifeLine(), findsNothing);
    expect(_statusLine(), findsNothing);
  });
}
