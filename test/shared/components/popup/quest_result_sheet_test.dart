import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/lore_fixtures.dart';
import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  QuestResult result, {
  VoidCallback? onContinue,
  String? characterName,
  int position = 1,
  int total = 1,
  bool isAcknowledging = false,
  bool hasAcknowledgeFailed = false,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: QuestResultSheet(
          result: result,
          onContinue: onContinue ?? () {},
          characterName: characterName,
          position: position,
          total: total,
          isAcknowledging: isAcknowledging,
          hasAcknowledgeFailed: hasAcknowledgeFailed,
        ),
      ),
    ),
  );
}

String _hpValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(HpDeltaBar.valueKey)).data!;

TextButton _button(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(QuestResultSheet.continueKey));

Finder _inSection(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

const String _trollPortrait = 'v1/troll_test.svg';

const Map<String, dynamic> _owl = {'id': 'pet-owl', 'name': 'Gufo reale'};

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      _trollPortrait,
    ]),
  );

  group('success', () {
    testWidgets('shows the D-03 content and hides the unchanged sections', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.headerKey)).data,
        'Vittoria',
      );
      expect(find.text('Lupi di Valantar'), findsOneWidget);
      expect(find.text('Caccia'), findsOneWidget);
      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('Lupo grigio')),
        findsOneWidget,
      );
      expect(find.byKey(QuestResultSheet.hpKey), findsOneWidget);
      expect(
        _inSection(QuestResultSheet.injuriesKey, find.text('Taglio profondo')),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.consumablesKey, find.byType(ItemRow)),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.spellsKey, find.text('Dardo di fuoco ×2')),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.rewardsKey, find.byType(CoinsDisplay)),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.rewardsKey, find.byType(ItemRow)),
        findsOneWidget,
      );
      expect(find.text('Esperienza: 200 → 260 (+60)'), findsOneWidget);
      expect(find.text('Livello 1 → 2'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.titleKey), findsNothing);
      expect(find.byKey(QuestResultSheet.spellLearnedKey), findsNothing);
      expect(find.byKey(QuestResultSheet.rescuedKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(QuestResultSheet.continueKey),
          matching: find.text('Continua'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the local resolution instant', (tester) async {
      final result = questResult(successResultJson());
      await _pump(tester, result);

      final expected = DateFormat(
        'dd/MM HH:mm',
      ).format(result.resolvedAt.toLocal());
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('the header uses the outcome ink', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.headerKey))
            .style
            ?.color,
        KlimmeckGuideTheme.darkBronze,
      );
    });
  });

  group('enemies fought', () {
    testWidgets('lists the enemies fought with quantities in BE order (D-07)', (
      tester,
    ) async {
      await _pump(tester, questResult(dungeonResultJson()));
      await tester.pumpAndSettle();

      final lines = ['3x Goblin', '1x Capo goblin', '1x Troll'];
      for (final line in lines) {
        expect(
          _inSection(QuestResultSheet.enemyKey, find.text(line)),
          findsOneWidget,
        );
      }
      final tops = [
        for (final line in lines) tester.getTopLeft(find.text(line)).dy,
      ];
      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));
    });

    testWidgets('a single enemy fought reads the bare name (D-07, D-02)', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('Lupo grigio')),
        findsOneWidget,
      );
      expect(find.text('1x Lupo grigio'), findsNothing);
    });

    testWidgets('shows the portrait of the strongest enemy fought (D-07, '
        'D-03)', (tester) async {
      await _pump(tester, questResult(dungeonResultJson()));
      await tester.pumpAndSettle();

      expect(
        _inSection(
          QuestResultSheet.enemyKey,
          find.byKey(QuestResultSheet.enemyPortraitKey),
        ),
        findsOneWidget,
      );
      final portrait = tester.widget<CachedSvg>(
        _inSection(QuestResultSheet.enemyPortraitKey, find.byType(CachedSvg)),
      );
      expect(portrait.url, CloudinaryAssets.url(_trollPortrait));
    });

    Finder silhouetteOfPortrait() => _inSection(
      QuestResultSheet.enemyPortraitKey,
      find.byType(ColorFiltered),
    );

    testWidgets('a victory shows the defeated enemies in clear (D-09)', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            enemies: [
              questEnemyJson(
                id: 'troll',
                name: 'Troll',
                xp: 90,
                imagePath: _trollPortrait,
                known: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.enemyPortraitKey), findsOneWidget);
      expect(silhouetteOfPortrait(), findsNothing);
    });

    testWidgets('after a defeat an unknown enemy stays a silhouette (D-09)', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            outcome: 'failure',
            enemies: [
              questEnemyJson(
                id: 'troll',
                name: 'Troll',
                xp: 90,
                imagePath: _trollPortrait,
                known: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(silhouetteOfPortrait(), findsOneWidget);
      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('Troll')),
        findsOneWidget,
      );
    });

    testWidgets("the portrait follows the strongest enemy's own known "
        '(D-08)', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            enemies: [
              questEnemyJson(id: 'wolf', xp: 10, known: false),
              questEnemyJson(
                id: 'troll',
                name: 'Troll',
                xp: 90,
                imagePath: _trollPortrait,
                known: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.enemyPortraitKey), findsOneWidget);
      expect(silhouetteOfPortrait(), findsNothing);
    });

    testWidgets('hides an unresolvable portrait and keeps the lines (D-03)', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.enemyPortraitKey), findsNothing);
      expect(
        _inSection(QuestResultSheet.enemyKey, find.byType(Image)),
        findsNothing,
      );
      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('Lupo grigio')),
        findsOneWidget,
      );
    });
  });

  group('dungeon and companion', () {
    testWidgets('a dungeon shows «Esplorazione: tappa k di N» (D-07)', (
      tester,
    ) async {
      await _pump(tester, questResult(dungeonResultJson()));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.stagesKey)).data,
        'Esplorazione: tappa 1 di 3',
      );
      expect(
        tester.getTopLeft(find.byKey(QuestResultSheet.stagesKey)).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byKey(QuestResultSheet.enemyKey)).dy,
        ),
      );
    });

    testWidgets('a dungeon victory shows all the stages (D-07)', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(dungeonResultJson(outcome: 'success', stagesCleared: 3)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.stagesKey)).data,
        'Esplorazione: tappa 3 di 3',
      );
    });

    testWidgets('no stage line outside a dungeon (D-07)', (tester) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.stagesKey), findsNothing);
    });

    testWidgets('a dungeon result renders like any combat result (D-11)', (
      tester,
    ) async {
      await _pump(tester, questResult(dungeonResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.headerKey)).data,
        QuestOutcome.failure.label,
      );
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.questTypeKey)).data,
        QuestType.dungeon.label,
      );
    });

    testWidgets('shows «Compagno ottenuto» for a companion reward (D-07)', (
      tester,
    ) async {
      await _pump(tester, questResult(questResultJson(rewardPet: _owl)));
      await tester.pumpAndSettle();

      final petLine = _inSection(
        QuestResultSheet.rewardsKey,
        find.byKey(QuestResultSheet.petRewardKey),
      );
      expect(petLine, findsOneWidget);
      expect(
        tester.widget<Text>(petLine).data,
        'Compagno ottenuto: Gufo reale',
      );
    });

    testWidgets('a companion-only reward still shows the rewards section '
        '(D-01, D-07)', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            coins: const {'gold': 0, 'silver': 0, 'copper': 0},
            rewardItems: const [],
            rewardPet: _owl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.rewardsKey), findsOneWidget);
      expect(
        _inSection(
          QuestResultSheet.rewardsKey,
          find.text('Compagno ottenuto: Gufo reale'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no companion line without a pet (D-07)', (tester) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.petRewardKey), findsNothing);
    });
  });

  group('HP animation', () {
    testWidgets('counts from hpBefore to hpAfter in the loss ink', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pump();
      expect(_hpValue(tester), '900 / 1200');

      await tester.pumpAndSettle();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.widget<HpDeltaBar>(find.byType(HpDeltaBar)).isLoss, isTrue);
    });

    testWidgets('a tap on the block skips to the end', (tester) async {
      // Senza oggetti: le quantità a matita delle card animano da sole.
      await _pump(
        tester,
        questResult(
          questResultJson(consumablesUsed: const [], rewardItems: const []),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(QuestResultSheet.hpKey));
      await tester.pump(const Duration(milliseconds: 100));
      final midway = int.parse(_hpValue(tester).split(' / ').first);
      expect(midway, greaterThan(640));

      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the button is enabled on the first frame', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(_button(tester).onPressed, isNotNull);
    });
  });

  testWidgets('failure: no rewards and no experience line', (tester) async {
    await _pump(tester, questResult(failureResultJson()));
    await tester.pumpAndSettle();

    expect(find.text('Sconfitta'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
    expect(find.byKey(QuestResultSheet.xpKey), findsNothing);
  });

  testWidgets('rescued: the aid as quest, no HP block, no rewards', (
    tester,
  ) async {
    await _pump(tester, questResult(rescuedResultJson()));

    expect(find.text('Sei stato salvato'), findsOneWidget);
    expect(find.text('Soccorso'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.hpKey), findsNothing);
    expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
  });

  group('death', () {
    testWidgets('shows the dead character and «Riposa in pace»', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        characterName: 'Aldo',
      );

      expect(find.text('È morto'), findsOneWidget);
      expect(find.text('Aldo'), findsOneWidget);
      expect(find.text('Recluta · Livello 1'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.hpKey), findsNothing);
      expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(QuestResultSheet.continueKey),
          matching: find.text('Riposa in pace'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.headerKey))
            .style
            ?.color,
        KlimmeckGuideTheme.deepNight,
      );
    });

    testWidgets('a historical sheet shows no name line', (tester) async {
      await _pump(tester, questResult(deathResultJson()));

      expect(find.text('Aldo'), findsNothing);
      expect(find.byKey(QuestResultSheet.deadNameKey), findsNothing);
      expect(find.text('Recluta · Livello 1'), findsOneWidget);
    });

    testWidgets('the button is disabled while acknowledging', (tester) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        isAcknowledging: true,
      );

      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('a failed acknowledgement shows the error line', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        hasAcknowledgeFailed: true,
      );

      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.acknowledgeErrorKey))
            .data,
        'Conferma non riuscita: riprova',
      );
      expect(_button(tester).onPressed, isNotNull);
    });
  });

  testWidgets('gmCompleted: no enemy and the title change', (tester) async {
    await _pump(tester, questResult(gmCompletedResultJson()));

    expect(find.text('Missione completata'), findsOneWidget);
    expect(find.text('Storia'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.enemyKey), findsNothing);
    expect(find.text('Recluta → Avventuriero'), findsOneWidget);
  });

  group('rescuers', () {
    testWidgets('counts the saved adventurers', (tester) async {
      await _pump(tester, questResult(rescuerSuccessResultJson()));

      expect(find.text('Hai salvato 2 avventurieri'), findsOneWidget);
    });

    testWidgets('one saved adventurer reads singular', (tester) async {
      await _pump(
        tester,
        questResult(questResultJson(rescuedCharacters: const ['c-2'])),
      );

      expect(find.text('Hai salvato 1 avventuriero'), findsOneWidget);
    });
  });

  group('degraded data', () {
    testWidgets('a missing spell reads «Magia sconosciuta»', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            spellsUsed: const [
              {'usages': 1, 'spell': null},
            ],
          ),
        ),
      );

      expect(find.text('Magia sconosciuta ×1'), findsOneWidget);
    });

    testWidgets('an unknown quest type shows no type line', (tester) async {
      await _pump(tester, questResult(questResultJson(questType: 'unknown')));

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestResultSheet.questTypeKey), findsNothing);
      expect(find.text('Caccia'), findsNothing);
    });

    testWidgets('shows the learned spell', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(spellLearned: const {'id': 's-9', 'name': 'Scudo'}),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.spellLearnedKey)).data,
        'Magia appresa: Scudo',
      );
    });
  });

  group('lore unlocked (BE Phase 16)', () {
    String lineOf(WidgetTester tester, String loreId) => tester
        .widget<Text>(find.byKey(QuestResultSheet.loreUnlockedKeyOf(loreId)))
        .data!;

    testWidgets('lists the lore unlocked right after the learned spell, in BE '
        'order (D-10)', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            spellLearned: const {'id': 's-9', 'name': 'Scudo'},
            loreUnlocked: [
              loreRefJson(),
              loreRefJson(
                id: 'lore-runes',
                name: 'Rune antiche',
                type: 'knowledge',
              ),
              loreRefJson(
                id: 'lore-mandragora',
                name: 'Mandragora',
                type: 'plant',
              ),
            ],
          ),
        ),
      );

      expect(
        lineOf(tester, 'lore-goblin'),
        'Nuova pagina del Bestiario: Goblin',
      );
      expect(lineOf(tester, 'lore-runes'), 'Conoscenza appresa: Rune antiche');
      expect(
        lineOf(tester, 'lore-mandragora'),
        'Nuova pagina del Bestiario: Mandragora',
      );
      final tops = [
        find.byKey(QuestResultSheet.spellLearnedKey),
        find.byKey(QuestResultSheet.loreUnlockedKeyOf('lore-goblin')),
        find.byKey(QuestResultSheet.loreUnlockedKeyOf('lore-runes')),
        find.byKey(QuestResultSheet.loreUnlockedKeyOf('lore-mandragora')),
      ].map((finder) => tester.getTopLeft(finder).dy).toList();
      for (var index = 1; index < tops.length; index++) {
        expect(tops[index], greaterThan(tops[index - 1]));
      }
    });

    testWidgets('labels animals as Bestiario pages and cities, gods, '
        'characters as knowledge (D-10)', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            loreUnlocked: [
              loreRefJson(id: 'lore-lupo', name: 'Lupo', type: 'animal'),
              loreRefJson(id: 'lore-bosa', name: 'Bosa', type: 'city'),
              loreRefJson(id: 'lore-dio', name: 'Andur', type: 'god'),
              loreRefJson(id: 'lore-eroe', name: 'Kliever', type: 'character'),
            ],
          ),
        ),
      );

      expect(lineOf(tester, 'lore-lupo'), 'Nuova pagina del Bestiario: Lupo');
      expect(lineOf(tester, 'lore-bosa'), 'Conoscenza appresa: Bosa');
      expect(lineOf(tester, 'lore-dio'), 'Conoscenza appresa: Andur');
      expect(lineOf(tester, 'lore-eroe'), 'Conoscenza appresa: Kliever');
    });

    testWidgets('a lore with an unknown type reads as knowledge (D-16)', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            loreUnlocked: [
              loreRefJson(id: 'lore-x', name: 'Arcano', type: 'dragon'),
            ],
          ),
        ),
      );

      expect(lineOf(tester, 'lore-x'), 'Conoscenza appresa: Arcano');
    });

    testWidgets('shows no lore line when nothing was unlocked (D-10)', (
      tester,
    ) async {
      for (final json in [questResultJson(), failureResultJson()]) {
        await _pump(tester, questResult(json));

        expect(find.textContaining('Conoscenza appresa'), findsNothing);
        expect(find.textContaining('Nuova pagina del Bestiario'), findsNothing);
      }
    });
  });

  group('counter', () {
    testWidgets('shows «k di N» in a queue', (tester) async {
      await _pump(
        tester,
        questResult(successResultJson()),
        position: 2,
        total: 3,
      );

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.counterKey)).data,
        '2 di 3',
      );
    });

    testWidgets('a single sheet has no counter', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(find.byKey(QuestResultSheet.counterKey), findsNothing);
    });
  });

  group('dismissal', () {
    testWidgets('the button calls onContinue once', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        questResult(successResultJson()),
        onContinue: () => calls++,
      );

      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('tapping anywhere else calls nothing', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        questResult(successResultJson()),
        onContinue: () => calls++,
      );

      await tester.tap(find.byKey(QuestResultSheet.headerKey));
      await tester.tapAt(const Offset(5, 5));
      await tester.ensureVisible(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.fling(
        find.byKey(QuestResultSheet.headerKey),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(calls, 0);
    });

    testWidgets('no AppBar and no exception in landscape', (tester) async {
      for (final json in [
        successResultJson(),
        failureResultJson(),
        rescuedResultJson(),
        deathResultJson(),
        gmCompletedResultJson(),
        rescuerSuccessResultJson(),
      ]) {
        await _pump(tester, questResult(json), position: 1, total: 2);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppBar), findsNothing);
      }
    });
  });
  group('layout (09-REVIEW WR-02)', () {
    testWidgets('a narrow surface keeps the parchment ratio and the button '
        'inside it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: QuestResultSheet(
              result: questResult(successResultJson()),
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final parchment = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CachedSvg &&
              widget.url == CloudinaryAssets.url(CloudinaryAssets.emptySheet),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(parchment.width / parchment.height, closeTo(315 / 375, 1e-6));
      final button = tester.getRect(find.byKey(QuestResultSheet.continueKey));
      expect(parchment.contains(button.topLeft), isTrue);
      expect(parchment.contains(button.bottomRight), isTrue);
    });
  });
  group('ambush report (Phase 16)', () {
    testWidgets('an ambush reads «Imboscata presso <città>» in place of the '
        'quest title (D-04, D-13)', (tester) async {
      await _pump(tester, questResult(ambushWonResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Imboscata presso Andogan'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.ambushPlaceKey), findsOneWidget);
      expect(find.byKey(QuestResultSheet.questTypeKey), findsNothing);
      expect(find.text('Lupi di Valantar'), findsNothing);
    });

    testWidgets('the ambush header keeps the outcome label and ink (D-04)', (
      tester,
    ) async {
      Text header() =>
          tester.widget<Text>(find.byKey(QuestResultSheet.headerKey));

      await _pump(tester, questResult(ambushWonResultJson()));
      expect(header().data, 'Vittoria');
      expect(header().style?.color, KlimmeckGuideTheme.darkBronze);

      await _pump(tester, questResult(ambushLostResultJson()));
      expect(header().data, 'Sconfitta');
      expect(header().style?.color, KlimmeckGuideTheme.royalCrimson);
    });

    testWidgets('the ambush header shows the local ambush instant (D-04)', (
      tester,
    ) async {
      await _pump(tester, questResult(ambushWonResultJson()));

      final expected = DateFormat(
        'dd/MM HH:mm',
      ).format(DateTime.utc(2026, 10, 27, 11, 20).toLocal());
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('the near city of a lost ambush is the one of the report '
        '(D-04)', (tester) async {
      await _pump(
        tester,
        questResult(ambushLostResultJson(nearCityName: 'Kliever')),
      );

      expect(find.text('Imboscata presso Kliever'), findsOneWidget);
    });

    testWidgets('a quest result keeps its title and type and no ambush line '
        '(D-04)', (tester) async {
      await _pump(tester, questResult(questResultJson()));

      expect(find.text('Lupi di Valantar'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.questTypeKey), findsOneWidget);
      expect(find.byKey(QuestResultSheet.ambushPlaceKey), findsNothing);
    });

    testWidgets('a lost ambush shows «Portato a <città>» right after «Ferite» '
        '(D-04, D-13)', (tester) async {
      await _pump(tester, questResult(ambushLostResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Portato a Bosa'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.reachedCityKey)).data,
        'Portato a Bosa',
      );
      expect(
        tester.getTopLeft(find.byKey(QuestResultSheet.reachedCityKey)).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(QuestResultSheet.injuriesKey)).dy,
        ),
      );
    });

    testWidgets('a won ambush has no «Portato a» line (D-04)', (tester) async {
      await _pump(tester, questResult(ambushWonResultJson()));

      expect(find.byKey(QuestResultSheet.reachedCityKey), findsNothing);
    });

    testWidgets('a quest result never shows «Portato a» (D-04)', (
      tester,
    ) async {
      await _pump(tester, questResult(failureResultJson()));

      expect(find.byKey(QuestResultSheet.reachedCityKey), findsNothing);
    });

    testWidgets('a won ambush shows the coins and the experience (D-04)', (
      tester,
    ) async {
      await _pump(tester, questResult(ambushWonResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.rewardsKey), findsOneWidget);
      expect(find.byType(CoinsDisplay), findsOneWidget);
      expect(find.text('Esperienza: 200 → 235 (+35)'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.levelKey), findsNothing);
    });

    testWidgets('a lost ambush shows no rewards and no experience '
        '(D-04, D-13)', (tester) async {
      await _pump(tester, questResult(ambushLostResultJson()));

      expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
      expect(find.byKey(QuestResultSheet.xpKey), findsNothing);
      expect(find.byKey(QuestResultSheet.reachedCityKey), findsOneWidget);
    });

    testWidgets('an ambush shows the enemies fought and the HP bar (D-04)', (
      tester,
    ) async {
      await _pump(tester, questResult(ambushWonResultJson()));
      await tester.pumpAndSettle();

      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('2x Bandito')),
        findsOneWidget,
      );
      expect(find.byKey(QuestResultSheet.hpKey), findsOneWidget);

      await _pump(tester, questResult(ambushLostResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.injuriesKey), findsOneWidget);
    });

    testWidgets('a lost ambush keeps «Continua» as the only close (D-04)', (
      tester,
    ) async {
      var continued = 0;
      await _pump(
        tester,
        questResult(ambushLostResultJson()),
        onContinue: () => continued++,
      );
      await tester.pumpAndSettle();

      expect(find.text('Continua'), findsOneWidget);
      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pump();

      expect(continued, 1);
    });
  });

  group('arrest and guard encounter (quick 261110-cgd)', () {
    String lineText(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key)).data!;

    testWidgets('an arrest says so and shows the confiscated coins, no '
        'rewards, no duration and no aid wait (quick 261110-cgd)', (
      tester,
    ) async {
      await _pump(tester, questResult(arrestResultJson()));
      await tester.pumpAndSettle();

      expect(
        lineText(tester, QuestResultSheet.arrestKey),
        'Sei stato arrestato.',
      );
      expect(
        _inSection(
          QuestResultSheet.confiscatedKey,
          find.text('Monete confiscate'),
        ),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.confiscatedKey, find.byType(CoinsDisplay)),
        findsOneWidget,
      );
      expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
      expect(find.textContaining('ore'), findsNothing);
      expect(find.textContaining('soccorso'), findsNothing);
    });

    testWidgets('an arrest with no coins lost shows no confiscation '
        '(quick 261110-cgd)', (tester) async {
      await _pump(tester, questResult(arrestResultJson(coinsLost: null)));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.arrestKey), findsOneWidget);
      expect(find.byKey(QuestResultSheet.confiscatedKey), findsNothing);
    });

    testWidgets('a won guard encounter says the pay was doubled and shows '
        'the server rewards (quick 261110-cgd)', (tester) async {
      await _pump(tester, questResult(guardEncounterResultJson()));
      await tester.pumpAndSettle();

      expect(
        lineText(tester, QuestResultSheet.guardEncounterKey),
        'Scontro durante la guardia: vittoria, paga raddoppiata',
      );
      expect(find.byKey(QuestResultSheet.rewardsKey), findsOneWidget);
    });

    testWidgets('a lost guard encounter says defeat with no aid wait '
        '(quick 261110-cgd)', (tester) async {
      await _pump(
        tester,
        questResult(guardEncounterResultJson(outcome: 'failure')),
      );
      await tester.pumpAndSettle();

      expect(
        lineText(tester, QuestResultSheet.guardEncounterKey),
        'Scontro durante la guardia: sconfitta',
      );
      expect(find.textContaining('soccorso'), findsNothing);
      expect(find.byKey(QuestResultSheet.arrestKey), findsNothing);
    });

    testWidgets('an ordinary result shows neither line (quick 261110-cgd)', (
      tester,
    ) async {
      await _pump(tester, questResult(questResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.arrestKey), findsNothing);
      expect(find.byKey(QuestResultSheet.confiscatedKey), findsNothing);
      expect(find.byKey(QuestResultSheet.guardEncounterKey), findsNothing);
    });
  });

  group('healed injuries (BE Phase 18)', () {
    String healedText(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(QuestResultSheet.healedKey)).data!;

    double topOf(WidgetTester tester, Key key) =>
        tester.getTopLeft(find.byKey(key)).dy;

    testWidgets(
      'Guarite sits between the HP bar and the injuries added (D-06)',
      (tester) async {
        await _pump(
          tester,
          questResult(
            questResultJson(
              injuriesAdded: const ['deepCut'],
              injuriesHealed: const ['contusion'],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(healedText(tester), 'Guarite: contusione');
        final hp = topOf(tester, QuestResultSheet.hpKey);
        final healed = topOf(tester, QuestResultSheet.healedKey);
        final injuries = topOf(tester, QuestResultSheet.injuriesKey);
        expect(hp, lessThan(healed));
        expect(healed, lessThan(injuries));
      },
    );

    testWidgets(
      'the healed labels are lowercase and in the order of the result (D-19)',
      (tester) async {
        await _pump(
          tester,
          questResult(
            questResultJson(injuriesHealed: const ['deepCut', 'contusion']),
          ),
        );
        await tester.pumpAndSettle();

        expect(healedText(tester), 'Guarite: taglio profondo, contusione');
      },
    );

    testWidgets('the healed line is hidden when nothing was healed (D-06)', (
      tester,
    ) async {
      await _pump(tester, questResult(questResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.healedKey), findsNothing);
    });

    testWidgets('a heal result shows the HP gain and the healed line (D-06)', (
      tester,
    ) async {
      await _pump(tester, questResult(healResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.widget<HpDeltaBar>(find.byType(HpDeltaBar)).isGain, isTrue);
      expect(healedText(tester), 'Guarite: contusione');
    });
  });

  group('companion xp (BE Phase 19)', () {
    double topOf(WidgetTester tester, Key key) =>
        tester.getTopLeft(find.byKey(key)).dy;

    testWidgets('shows the companion xp gained (D-03)', (tester) async {
      await _pump(tester, questResult(questResultJson(petXpGained: 12)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.companionXpKey)).data,
        'Il tuo compagno guadagna 12 PE',
      );
    });

    testWidgets('the companion line sits right after the xp line (D-03)', (
      tester,
    ) async {
      await _pump(tester, questResult(questResultJson(petXpGained: 12)));
      await tester.pumpAndSettle();

      final xp = topOf(tester, QuestResultSheet.xpKey);
      final companion = topOf(tester, QuestResultSheet.companionXpKey);
      final level = topOf(tester, QuestResultSheet.levelKey);
      expect(xp, lessThan(companion));
      expect(companion, lessThan(level));
    });

    testWidgets('no companion line at zero (D-03)', (tester) async {
      await _pump(tester, questResult(questResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.companionXpKey), findsNothing);
      expect(find.textContaining('Il tuo compagno'), findsNothing);
    });

    testWidgets('the companion line shows without character xp (D-03)', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(questResultJson(xpGained: 0, xpAfter: 200, petXpGained: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(QuestResultSheet.xpKey), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.companionXpKey)).data,
        'Il tuo compagno guadagna 5 PE',
      );
    });
  });

  group('dungeon turns (Phase 20)', () {
    const turnsKey = QuestResultSheet.turnsKey;

    String? textOf(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key)).data;

    testWidgets(
      'a dungeon with turns shows one turn line in the stages slot (D-21)',
      (tester) async {
        await _pump(
          tester,
          questResult(
            dungeonResultJson(
              turnsTotal: 8,
              turnsCompleted: 3,
              lastTurn: 4,
              lastTurnKind: 'exploration',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          textOf(tester, turnsKey),
          'Caduto al turno 4 di 8, in esplorazione',
        );
        expect(find.byKey(QuestResultSheet.stagesKey), findsNothing);
        expect(
          tester.getTopLeft(find.byKey(turnsKey)).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byKey(QuestResultSheet.enemyKey)).dy,
          ),
        );
      },
    );

    testWidgets(
      'a won dungeon aid shows the reached turn and the rescued count (D-21)',
      (tester) async {
        await _pump(tester, questResult(aidDungeonResultJson()));
        await tester.pumpAndSettle();

        expect(textOf(tester, turnsKey), 'Ferito raggiunto al turno 4 di 8');
        expect(find.byKey(QuestResultSheet.stagesKey), findsNothing);
        expect(
          textOf(tester, QuestResultSheet.rescuedKey),
          'Hai salvato 1 avventuriero',
        );
      },
    );

    testWidgets(
      'no prize-share line: the share is only in the rewards (D-20, D-21)',
      (tester) async {
        await _pump(tester, questResult(aidDungeonResultJson()));
        await tester.pumpAndSettle();

        expect(find.textContaining('proporzione'), findsNothing);
      },
    );

    testWidgets('without turns the stages line stays (D-24)', (tester) async {
      await _pump(tester, questResult(dungeonResultJson()));
      await tester.pumpAndSettle();

      expect(
        textOf(tester, QuestResultSheet.stagesKey),
        'Esplorazione: tappa 1 di 3',
      );
      expect(find.byKey(turnsKey), findsNothing);
    });

    testWidgets('no turn line outside a dungeon (D-21)', (tester) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(find.byKey(turnsKey), findsNothing);
    });
  });
}
