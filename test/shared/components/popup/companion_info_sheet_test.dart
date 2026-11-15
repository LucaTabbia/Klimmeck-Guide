import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info_sheet.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const String _worgId = 'pet-worg';
const String _worgImage = 'v1/pets/worg.svg';

const _attack = <String, dynamic>{
  'base': [
    {'type': 'cut', 'power': 12},
  ],
  'energy': [
    {'type': 'fire', 'power': 5},
  ],
};
const _defense = <String, dynamic>{
  'base': [
    {'type': 'blunt', 'power': 4},
  ],
  'energy': [],
};

Pet _worg({Object? recoveryTime, num? speedModifier}) => Pet.fromJson(
  petJson(
    id: _worgId,
    name: 'Worg',
    speedModifier: speedModifier,
    rarity: 'rare',
    imagePath: _worgImage,
    maxXp: 10,
    maxLifePoints: 100,
    recoveryTime: recoveryTime,
    attack: _attack,
    defense: _defense,
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  Pet? pet,
  String? name,
  int? level,
  int? xp,
  CompanionVitality? vitality,
  Duration? potionWait,
  bool? isEquipped,
  VoidCallback? onToggle,
  VoidCallback? onRename,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompanionInfoSheet(
            pet: pet ?? _worg(),
            name: name,
            level: level,
            xp: xp,
            vitality: vitality,
            potionWait: potionWait,
            isEquipped: isEquipped,
            onToggle: onToggle,
            onRename: onRename,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String? _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
      _worgImage,
    ]),
  );

  testWidgets('shows the display name, the species when named and the card '
      '(D-20, D-22)', (tester) async {
    await _pump(tester, name: 'Fenrir');

    expect(_textOf(tester, CompanionInfo.titleKey), 'Fenrir');
    expect(
      tester.widget<Text>(find.byKey(CompanionInfo.titleKey)).style?.color,
      RarityType.rare.color,
    );
    expect(_textOf(tester, CompanionInfo.speciesKey), 'Worg');
    final card = tester.widget<CompanionCard>(find.byType(CompanionCard));
    expect(card.name, 'Fenrir');
    expect(card.pet.id, _worgId);
  });

  testWidgets('an unnamed companion reads the species as title only (D-20)', (
    tester,
  ) async {
    await _pump(tester);

    expect(_textOf(tester, CompanionInfo.titleKey), 'Worg');
    expect(find.byKey(CompanionInfo.speciesKey), findsNothing);
  });

  testWidgets('a resting companion reads «Vita» and «A riposo: in forze fra …» '
      '(D-09)', (tester) async {
    await _pump(
      tester,
      vitality: const CompanionResting(
        life: 40,
        maxLifePoints: 100,
        remaining: Duration(minutes: 80),
      ),
    );

    expect(_textOf(tester, CompanionInfo.lifeKey), 'Vita: 40 / 100');
    expect(
      _textOf(tester, CompanionInfo.statusKey),
      'A riposo: in forze fra 1 h 20 min',
    );
  });

  testWidgets('a defeated companion reads «Sconfitto: torna fra …» (D-09)', (
    tester,
  ) async {
    await _pump(
      tester,
      vitality: const CompanionDefeated(
        life: 1,
        maxLifePoints: 100,
        remaining: Duration(hours: 3),
      ),
    );

    expect(_textOf(tester, CompanionInfo.lifeKey), 'Vita: 1 / 100');
    expect(
      _textOf(tester, CompanionInfo.statusKey),
      'Sconfitto: torna fra 3 h',
    );
  });

  testWidgets('a steady companion has the life line and no status (D-09)', (
    tester,
  ) async {
    await _pump(
      tester,
      vitality: const CompanionSteady(life: 100, maxLifePoints: 100),
    );

    expect(_textOf(tester, CompanionInfo.lifeKey), 'Vita: 100 / 100');
    expect(find.byKey(CompanionInfo.statusKey), findsNothing);
  });

  testWidgets('the potion wait shows only while it runs (D-05)', (
    tester,
  ) async {
    await _pump(tester, potionWait: const Duration(minutes: 20));
    expect(
      _textOf(tester, CompanionInfo.potionWaitKey),
      'Pozione: pronta fra 20 min',
    );

    await _pump(tester);
    expect(find.byKey(CompanionInfo.potionWaitKey), findsNothing);
  });

  testWidgets('shows «Livello 3» only when a level is served (D-37)', (
    tester,
  ) async {
    await _pump(tester, level: 3);
    expect(_textOf(tester, CompanionInfo.levelKey), 'Livello 3');

    await _pump(tester);
    expect(find.byKey(CompanionInfo.levelKey), findsNothing);
  });

  testWidgets(
    'the life line reads the companion\'s own max carried by the vitality '
    '(D-38)',
    (tester) async {
      await _pump(
        tester,
        vitality: const CompanionSteady(life: 150, maxLifePoints: 200),
      );

      expect(_textOf(tester, CompanionInfo.lifeKey), 'Vita: 150 / 200');
    },
  );

  testWidgets('«Recupero completo» appears only with a served recovery time '
      '(D-01, D-25)', (tester) async {
    await _pump(
      tester,
      pet: _worg(recoveryTime: const Duration(hours: 10).inMilliseconds),
    );
    expect(
      _textOf(tester, CompanionInfo.recoveryTimeKey),
      'Recupero completo: 10 h',
    );

    await _pump(tester);
    expect(find.byKey(CompanionInfo.recoveryTimeKey), findsNothing);
  });

  testWidgets(
    'attack, defense and experience in the text, the speed once on the '
    'card (D-22)',
    (tester) async {
      await _pump(tester, pet: _worg(speedModifier: 2), xp: 3);

      expect(find.text('Velocità ×2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CompanionCard),
          matching: find.text('Velocità ×2'),
        ),
        findsOneWidget,
      );
      expect(
        _textOf(tester, CompanionInfo.attackKey),
        'Attacco: tagliente 12, fuoco 5',
      );
      expect(
        _textOf(tester, CompanionInfo.defenseKey),
        'Difesa: contundente 4',
      );
      expect(_textOf(tester, CompanionInfo.xpKey), 'Esperienza: 3 / 10');
    },
  );

  testWidgets('without served stats no stat row is shown (D-22)', (
    tester,
  ) async {
    await _pump(tester, pet: Pet.fromJson(catPetJson()));

    expect(find.textContaining('Velocità'), findsNothing);
    expect(find.byKey(CompanionInfo.attackKey), findsNothing);
    expect(find.byKey(CompanionInfo.defenseKey), findsNothing);
    expect(find.byKey(CompanionInfo.xpKey), findsNothing);
    expect(find.byKey(CompanionInfo.lifeKey), findsNothing);
  });

  group('rename (D-19)', () {
    testWidgets('the rename action appears only with onRename (D-19)', (
      tester,
    ) async {
      await _pump(tester, name: 'Fenrir');

      expect(find.byKey(CompanionInfo.renameKey), findsNothing);
    });

    testWidgets('reads «Dai un nome» / «Cambia nome» (D-19)', (tester) async {
      await _pump(tester, onRename: () {});
      expect(_textOf(tester, CompanionInfo.renameKey), 'Dai un nome');

      await _pump(tester, name: 'Fenrir', onRename: () {});
      expect(_textOf(tester, CompanionInfo.renameKey), 'Cambia nome');
    });

    testWidgets('tapping it calls onRename once with a 44 px target (D-19)', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, name: 'Fenrir', onRename: () => taps++);

      final target = find.ancestor(
        of: find.byKey(CompanionInfo.renameKey),
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(target.first).height, greaterThanOrEqualTo(44));
      await tester.ensureVisible(find.byKey(CompanionInfo.renameKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CompanionInfo.renameKey));

      expect(taps, 1);
    });
  });

  group('bookmark (D-22)', () {
    testWidgets('no bookmark without isEquipped (D-22)', (tester) async {
      await _pump(tester);

      expect(find.byType(BookmarkRibbon), findsNothing);
    });

    testWidgets('the bookmark is the equip toggle when isEquipped is given '
        '(D-22)', (tester) async {
      var taps = 0;
      await _pump(tester, isEquipped: true, onToggle: () => taps++);

      final ribbon = tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));
      expect(ribbon.isMarked, isTrue);
      await tester.tap(
        find.descendant(
          of: find.byType(BookmarkRibbon),
          matching: find.byType(RotatedBox),
        ),
      );
      expect(taps, 1);
    });
  });

  testWidgets('no Material dialog button and no overflow in landscape '
      '(rule 1)', (tester) async {
    await _pump(
      tester,
      pet: _worg(
        speedModifier: 2,
        recoveryTime: const Duration(hours: 10).inMilliseconds,
      ),
      name: 'Fenrir',
      level: 3,
      xp: 3,
      vitality: const CompanionDefeated(
        life: 1,
        maxLifePoints: 100,
        remaining: Duration(hours: 3),
      ),
      potionWait: const Duration(minutes: 20),
      isEquipped: false,
      onToggle: () {},
      onRename: () {},
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });
}
