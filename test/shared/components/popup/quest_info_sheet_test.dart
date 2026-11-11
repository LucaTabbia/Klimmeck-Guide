import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/equipment_item_card.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const _enemy = {
  'id': 'e-1',
  'name': 'Arbusto maligno',
  'imagePath': 'assets/images/arbustoMaligno.png',
};

const _goblinPortrait = 'v1/goblin_test.svg';
const _goblinChiefPortrait = 'v1/goblin-chief_test.svg';

const _potion = {
  'quantity': 2,
  'item': {'id': 'l-1', 'name': 'Pozione', 'description': 'd'},
};

List<Map<String, dynamic>> _goblinPack({
  bool goblinsKnown = true,
  bool chiefKnown = true,
}) => [
  questEnemyJson(
    id: 'goblin',
    name: 'Goblin',
    imagePath: _goblinPortrait,
    xp: 7,
    quantity: 3,
    known: goblinsKnown,
  ),
  questEnemyJson(
    id: 'goblin-chief',
    name: 'Capo goblin',
    imagePath: _goblinChiefPortrait,
    xp: 21,
    known: chiefKnown,
  ),
];

Finder _inCombat(String text) => find.descendant(
  of: find.byKey(QuestInfoSheet.combatFamilyKey),
  matching: find.text(text),
);

Future<void> _pump(
  WidgetTester tester,
  Quest? quest, {
  QuestViewer? viewer,
  String? stateLabel,
  VoidCallback? onAbandon,
  TravelPreview? travelPreview,
  List<InjuryType>? characterInjuries,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestInfoSheet(
            quest: quest,
            viewer: viewer,
            stateLabel: stateLabel,
            onAbandon: onAbandon,
            travelPreview: travelPreview,
            characterInjuries: characterInjuries,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Color? _colorOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style?.color;

TravelPreview _travelPreview({bool arrivesAlive = true}) =>
    TravelPreview.fromJson(
      travelPreviewJson(
        food: [travelFoodItemJson()],
        hpLost: arrivesAlive ? 0 : 20910,
        arrivesAlive: arrivesAlive,
      ),
    );

Quest _cureQuest({
  String type = 'heal',
  Object? share = 0.5,
  Object? canHeal = const ['contusion', 'deepCut'],
}) => buildQuest(
  type: type,
  prizes: {'cure': questCureJson(share: share, canHeal: canHeal)},
);

Finder _inFamily(Key familyKey, Key lineKey) =>
    find.descendant(of: find.byKey(familyKey), matching: find.byKey(lineKey));

String? _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;

Finder _travelLineIn(Key familyKey) => find.descendant(
  of: find.byKey(familyKey),
  matching: find.byKey(QuestInfoSheet.travelLineKey),
);

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      _goblinPortrait,
      _goblinChiefPortrait,
    ]),
  );

  group('families', () {
    const expected = {
      'hunt': 'combat',
      'enemy': 'combat',
      'boss': 'combat',
      'dungeon': 'combat',
      'aid': 'combat',
      'story': 'narrative',
      'worldMission': 'narrative',
      'heal': 'service',
      'job': 'service',
      'study': 'service',
      'crime': 'service',
      'guard': 'service',
    };
    final keys = {
      'combat': QuestInfoSheet.combatFamilyKey,
      'narrative': QuestInfoSheet.narrativeFamilyKey,
      'service': QuestInfoSheet.serviceFamilyKey,
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key} renders the ${entry.value} family', (
        tester,
      ) async {
        await _pump(tester, buildQuest(type: entry.key, requiredPoints: 3000));

        expect(tester.takeException(), isNull);
        expect(find.byKey(keys[entry.value]!), findsOneWidget);
        for (final other in keys.entries.where((k) => k.key != entry.value)) {
          expect(find.byKey(other.value), findsNothing);
        }
      });
    }
  });

  group('combat', () {
    testWidgets('shows the portrait of the strongest enemy (D-02, D-03)', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'enemy', enemies: _goblinPack()));

      final portrait = find.byKey(QuestInfoSheet.enemyPortraitKey);
      expect(portrait, findsOneWidget);
      final svg = tester.widget<CachedSvg>(
        find.descendant(of: portrait, matching: find.byType(CachedSvg)),
      );
      expect(svg.url, CloudinaryAssets.url(_goblinChiefPortrait));
      expect(find.textContaining('Tempo richiesto: '), findsOneWidget);
    });

    testWidgets('lists one line per enemy type in BE order (D-02)', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'enemy', enemies: _goblinPack()));

      final goblins = _inCombat('3x Goblin');
      final chief = _inCombat('1x Capo goblin');
      expect(goblins, findsOneWidget);
      expect(chief, findsOneWidget);
      expect(
        tester.getTopLeft(goblins).dy,
        lessThan(tester.getTopLeft(chief).dy),
      );
    });

    testWidgets('an unknown strongest enemy is a silhouette and its lines '
        'stay (D-08)', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'enemy', enemies: _goblinPack(chiefKnown: false)),
      );

      final silhouette = find.descendant(
        of: find.byKey(QuestInfoSheet.enemyPortraitKey),
        matching: find.byType(ColorFiltered),
      );
      expect(silhouette, findsOneWidget);
      final svg = tester.widget<CachedSvg>(
        find.descendant(of: silhouette, matching: find.byType(CachedSvg)),
      );
      expect(svg.url, CloudinaryAssets.url(_goblinChiefPortrait));
      expect(_inCombat('3x Goblin'), findsOneWidget);
      expect(_inCombat('1x Capo goblin'), findsOneWidget);
    });

    testWidgets('a known strongest enemy is drawn in clear beside unknown '
        'ones (D-08)', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'enemy', enemies: _goblinPack(goblinsKnown: false)),
      );

      expect(
        find.descendant(
          of: find.byKey(QuestInfoSheet.enemyPortraitKey),
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
      );
      expect(find.byKey(QuestInfoSheet.enemyPortraitKey), findsOneWidget);
    });

    testWidgets('a single enemy with quantity 1 reads the bare name (D-02)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(
          type: 'enemy',
          enemies: [
            {'quantity': 1, 'known': true, 'enemy': _enemy},
          ],
        ),
      );

      expect(find.text('Arbusto maligno'), findsOneWidget);
      expect(find.text('1x Arbusto maligno'), findsNothing);
    });

    testWidgets(
      'hides the portrait of an unresolvable imagePath and keeps the name (D-03)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(
            type: 'enemy',
            enemies: [
              {'quantity': 1, 'known': true, 'enemy': _enemy},
            ],
          ),
        );

        expect(find.byKey(QuestInfoSheet.enemyPortraitKey), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(find.text('Arbusto maligno'), findsOneWidget);
      },
    );

    testWidgets('shows «Consigliati» under the enemy lines (D-04)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(
          type: 'enemy',
          enemies: _goblinPack(),
          recommendedLoot: [_potion],
        ),
      );

      final title = _inCombat('Consigliati');
      expect(title, findsOneWidget);
      expect(_inCombat('2x Pozione'), findsOneWidget);
      expect(
        tester.getTopLeft(title).dy,
        greaterThan(tester.getTopLeft(_inCombat('1x Capo goblin')).dy),
      );
    });

    testWidgets('omits «Consigliati» in combat when the list is empty (D-04)', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'enemy', enemies: _goblinPack()));

      expect(find.text('Consigliati'), findsNothing);
    });

    testWidgets(
      'many enemies and Consigliati do not overflow in landscape (D-02, D-04)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(
            type: 'enemy',
            enemies: [
              for (var i = 0; i < 6; i++)
                questEnemyJson(id: 'e-$i', name: 'Nemico $i', quantity: 3),
            ],
            recommendedLoot: [
              for (var i = 0; i < 4; i++)
                {
                  'quantity': 1,
                  'item': {
                    'id': 'l-$i',
                    'name': 'Oggetto $i',
                    'description': 'd',
                  },
                },
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('aid shows the enemy name and no cost line', (tester) async {
      await _pump(
        tester,
        buildQuest(
          type: 'aid',
          requiredPoints: null,
          enemies: [questEnemyJson(xp: null)],
        ),
        viewer: buildViewer(twitchPoints: 1200),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestInfoSheet.combatFamilyKey), findsOneWidget);
      expect(find.text('Lupo grigio'), findsOneWidget);
      expect(find.textContaining('Punti canale'), findsNothing);
    });

    testWidgets('renders without enemy and without image', (tester) async {
      await _pump(tester, buildQuest(type: 'enemy'));

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('narrative', () {
    final lore = [
      {'id': 'l-1', 'name': 'Il patto', 'description': 'Molto tempo fa…'},
    ];

    testWidgets('shows lore and a blood red insufficient balance', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(type: 'story', requiredPoints: 3000, lore: lore),
        viewer: buildViewer(twitchPoints: 1200),
      );

      expect(find.text('Molto tempo fa…'), findsOneWidget);
      final cost = find.text('Punti canale: 1200 / 3000');
      expect(cost, findsOneWidget);
      expect(_colorOf(tester, cost), KlimmeckGuideTheme.bloodRed);
    });

    testWidgets('a sufficient balance is not blood red', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'story', requiredPoints: 3000, lore: lore),
        viewer: buildViewer(twitchPoints: 5000),
      );

      final cost = find.text('Punti canale: 5000 / 3000');
      expect(cost, findsOneWidget);
      expect(_colorOf(tester, cost), isNot(KlimmeckGuideTheme.bloodRed));
    });

    testWidgets('renders without lore', (tester) async {
      await _pump(tester, buildQuest(type: 'story', requiredPoints: 3000));

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestInfoSheet.narrativeFamilyKey), findsOneWidget);
    });

    testWidgets('shows slots per rank for a world mission', (tester) async {
      await _pump(
        tester,
        buildQuest(
          type: 'worldMission',
          requiredPoints: 3000,
          slots: [
            {'title': 'hero', 'count': 5},
            {'title': 'paladin', 'count': 4},
          ],
        ),
      );

      expect(find.text('Eroe: 0 / 5'), findsOneWidget);
      expect(find.text('Paladino: 0 / 4'), findsOneWidget);
    });
  });

  group('announcement', () {
    const announcement = 'Il mugnaio di Bosa cerca aiuto contro i lupi.';
    final families = {
      'enemy': QuestInfoSheet.combatFamilyKey,
      'job': QuestInfoSheet.serviceFamilyKey,
      'story': QuestInfoSheet.narrativeFamilyKey,
    };
    final familyNames = {
      'enemy': 'combat',
      'job': 'service',
      'story': 'narrative',
    };

    for (final entry in families.entries) {
      testWidgets(
        'shows the announcement under the title in the ${familyNames[entry.key]} family (D-05)',
        (tester) async {
          await _pump(
            tester,
            buildQuest(
              type: entry.key,
              requiredPoints: 3000,
              description: announcement,
            ),
          );

          final description = find.byKey(QuestInfoSheet.descriptionKey);
          expect(description, findsOneWidget);
          final text = tester.widget<Text>(description);
          expect(text.data, announcement);
          expect(text.style?.fontStyle, FontStyle.italic);
          final titleY = tester.getTopLeft(find.text('Il lupo del bosco')).dy;
          final descriptionY = tester.getTopLeft(description).dy;
          expect(titleY, lessThan(descriptionY));
          expect(
            descriptionY,
            lessThan(tester.getTopLeft(find.byKey(entry.value)).dy),
          );
        },
      );
    }

    testWidgets('omits the announcement when null or empty (D-05)', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'enemy'));
      expect(find.byKey(QuestInfoSheet.descriptionKey), findsNothing);

      await _pump(tester, buildQuest(type: 'enemy', description: ''));
      expect(find.byKey(QuestInfoSheet.descriptionKey), findsNothing);
    });

    testWidgets('a long announcement scrolls without overflow (D-05)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(
          type: 'enemy',
          enemies: _goblinPack(),
          description: List.filled(40, announcement).join(' '),
        ),
      );

      expect(tester.takeException(), isNull);
      final description = find.byKey(QuestInfoSheet.descriptionKey);
      expect(description, findsOneWidget);
      expect(
        find.ancestor(
          of: description,
          matching: find.descendant(
            of: find.byType(QuestInfoSheet),
            matching: find.byType(SingleChildScrollView),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('companion prize', () {
    const owl = {'id': 'pet-owl', 'name': 'Gufo reale'};

    testWidgets(
      'shows «Compagno in premio» when the prize carries a pet (D-06)',
      (tester) async {
        await _pump(tester, buildQuest(prizes: {'pet': owl}));

        final line = find.byKey(QuestInfoSheet.petPrizeKey);
        expect(line, findsOneWidget);
        expect(
          tester.widget<Text>(line).data,
          'Compagno in premio: Gufo reale',
        );
      },
    );

    testWidgets('no companion line without a pet (D-06)', (tester) async {
      await _pump(tester, buildQuest(prizes: {'xpPrize': 10}));

      expect(find.byKey(QuestInfoSheet.petPrizeKey), findsNothing);
    });

    testWidgets('a pet prize with coins does not overflow (D-06)', (
      tester,
    ) async {
      seedSvgCache([
        CloudinaryAssets.goldCoin,
        CloudinaryAssets.silverCoin,
        CloudinaryAssets.copperCoin,
      ]);
      await _pump(
        tester,
        buildQuest(
          prizes: {
            'prizeCoins': {'gold': 1, 'silver': 0, 'copper': 0},
            'pet': owl,
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestInfoSheet.petPrizeKey), findsOneWidget);
    });

    final itemVariants = <String, (Map<String, dynamic>, Type)>{
      'equipment': (equipmentAssetJson(), EquipmentItemCard),
      'loot': (lootAssetJson(), LootItemCard),
    };
    for (final MapEntry(key: variant, value: (prizeItem, cardType))
        in itemVariants.entries) {
      testWidgets(
        'coins, a prize item ($variant) and a pet keep the card square (D-06)',
        (tester) async {
          seedSvgCache([
            CloudinaryAssets.goldCoin,
            CloudinaryAssets.silverCoin,
            CloudinaryAssets.copperCoin,
            CloudinaryAssets.emptyCardSheet,
            CloudinaryAssets.weaponType,
            CloudinaryAssets.healEffect,
          ]);
          await _pump(
            tester,
            buildQuest(
              prizes: {
                'prizeCoins': {'gold': 1, 'silver': 0, 'copper': 0},
                'prizeItem': prizeItem,
                'pet': owl,
              },
            ),
          );

          expect(tester.takeException(), isNull);
          final card = find.byType(cardType);
          final requested = switch (tester.widget(card)) {
            EquipmentItemCard(:final size) => size,
            LootItemCard(:final size) => size,
            _ => fail('unexpected card'),
          };
          expect(tester.getSize(card), Size(requested, requested));
          expect(find.byKey(QuestInfoSheet.petPrizeKey), findsOneWidget);
        },
      );
    }
  });

  group('fixed types (QGEN-04)', () {
    testWidgets(
      'dungeon shows its stage enemies and Consigliati in the combat family (D-11)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(
            type: 'dungeon',
            enemies: [
              questEnemyJson(id: 'goblin', name: 'Goblin', quantity: 3, xp: 7),
              questEnemyJson(id: 'goblin-chief', name: 'Capo goblin', xp: 21),
              questEnemyJson(id: 'troll', name: 'Troll', xp: 126),
            ],
            recommendedLoot: [_potion],
          ),
        );

        expect(tester.takeException(), isNull);
        final lines = ['3x Goblin', '1x Capo goblin', '1x Troll'];
        final tops = [
          for (final line in lines) tester.getTopLeft(_inCombat(line)).dy,
        ];
        expect(tops[0], lessThan(tops[1]));
        expect(tops[1], lessThan(tops[2]));
        expect(_inCombat('Consigliati'), findsOneWidget);
        expect(find.textContaining('Qualsiasi rango'), findsNothing);
      },
    );

    testWidgets(
      'crime and guard show the service family with the announcement and no portrait (D-11, D-16)',
      (tester) async {
        for (final type in ['crime', 'guard']) {
          await _pump(
            tester,
            buildQuest(type: type, description: 'Serve una mano discreta.'),
          );

          expect(tester.takeException(), isNull, reason: type);
          expect(
            find.byKey(QuestInfoSheet.serviceFamilyKey),
            findsOneWidget,
            reason: type,
          );
          expect(
            find.byKey(QuestInfoSheet.descriptionKey),
            findsOneWidget,
            reason: type,
          );
          expect(
            find.byKey(QuestInfoSheet.enemyPortraitKey),
            findsNothing,
            reason: type,
          );
        }
      },
    );
  });

  group('cost and title', () {
    testWidgets('an enemy never shows the cost line', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'enemy', requiredPoints: 3000),
        viewer: buildViewer(),
      );

      expect(find.textContaining('Punti canale'), findsNothing);
    });

    testWidgets('an ineligible required title is blood red', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'story', minTitle: 'paladin', requiredPoints: 3000),
        viewer: buildViewer(title: TitleType.mage),
      );

      final title = find.text('Titolo richiesto: Paladino');
      expect(title, findsOneWidget);
      expect(_colorOf(tester, title), KlimmeckGuideTheme.bloodRed);
    });
  });

  group('service', () {
    testWidgets('shows the recommended loot', (tester) async {
      await _pump(
        tester,
        buildQuest(
          type: 'heal',
          recommendedLoot: [
            {
              'quantity': 2,
              'item': {'id': 'l-1', 'name': 'Pozione', 'description': 'd'},
            },
          ],
        ),
      );

      expect(find.text('Consigliati'), findsOneWidget);
      expect(find.text('2x Pozione'), findsOneWidget);
    });

    testWidgets('renders without recommended loot', (tester) async {
      await _pump(tester, buildQuest(type: 'heal'));

      expect(tester.takeException(), isNull);
      expect(find.text('Consigliati'), findsNothing);
    });
  });

  group('blocked reason and state label', () {
    testWidgets('a busy lane is explained', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'hunt'),
        viewer: buildViewer(
          quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
        ),
      );

      final reason = find.byKey(QuestInfoSheet.blockedReasonKey);
      expect(reason, findsOneWidget);
      expect(
        tester.widget<Text>(reason).data,
        'Hai già una missione di questo tipo in corso',
      );
    });

    testWidgets('shows the state label only when given', (tester) async {
      await _pump(tester, buildQuest(type: 'hunt'), stateLabel: 'In viaggio');
      expect(
        tester.widget<Text>(find.byKey(QuestInfoSheet.stateLabelKey)).data,
        'In viaggio',
      );

      await _pump(tester, buildQuest(type: 'hunt'));
      expect(find.byKey(QuestInfoSheet.stateLabelKey), findsNothing);
    });

    testWidgets('offers no abandon action without a callback', (tester) async {
      await _pump(
        tester,
        buildQuest(type: 'boss'),
        stateLabel: 'In attesa del gruppo 1/3',
      );

      expect(find.byKey(QuestInfoSheet.abandonKey), findsNothing);
    });

    testWidgets('the abandon action calls back once', (tester) async {
      var abandons = 0;
      await _pump(
        tester,
        buildQuest(type: 'boss'),
        stateLabel: 'In attesa del gruppo 1/3',
        onAbandon: () => abandons++,
      );

      final action = find.byKey(QuestInfoSheet.abandonKey);
      expect(
        find.descendant(of: action, matching: find.text('Abbandona il gruppo')),
        findsOneWidget,
      );
      await tester.ensureVisible(action);
      await tester.tap(action);

      expect(abandons, 1);
    });

    testWidgets('the abandon action reads in blood red body text', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'boss'), onAbandon: () {});

      final style = tester
          .renderObject<RenderParagraph>(find.text(QuestInfoSheet.abandonLabel))
          .text
          .style!;
      expect(style.color, KlimmeckGuideTheme.bloodRed);
      expect(
        style.fontFamily,
        KlimmeckGuideTheme.instance.bodyLarge.fontFamily,
      );
    });
  });

  testWidgets('has no horizontal drag gesture of its own', (tester) async {
    await _pump(
      tester,
      buildQuest(
        type: 'enemy',
        enemies: [
          {'quantity': 1, 'known': true, 'enemy': _enemy},
        ],
      ),
    );

    final detectors = tester.widgetList<GestureDetector>(
      find.descendant(
        of: find.byType(QuestInfoSheet),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(detectors.where((d) => d.onHorizontalDragUpdate != null), isEmpty);
  });

  testWidgets('a null quest renders only the parchment', (tester) async {
    await _pump(tester, null);

    expect(tester.takeException(), isNull);
    expect(find.byKey(QuestInfoSheet.combatFamilyKey), findsNothing);
  });

  group('travel line', () {
    const coveredText = 'Viaggio: 1x Razione da viaggio · nessuna perdita';
    const starvingText = 'Viaggio: Non hai cibo a sufficienza per il viaggio';

    testWidgets(
      'a combat sheet shows the travel line in its costs block (D-04)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(type: 'hunt'),
          travelPreview: _travelPreview(),
        );

        final line = _travelLineIn(QuestInfoSheet.combatFamilyKey);
        expect(line, findsOneWidget);
        expect(tester.widget<Text>(line).data, coveredText);
      },
    );

    testWidgets(
      'a service sheet shows the travel line in its costs block (D-04)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(type: 'crime'),
          travelPreview: _travelPreview(),
        );

        final line = _travelLineIn(QuestInfoSheet.serviceFamilyKey);
        expect(line, findsOneWidget);
        expect(tester.widget<Text>(line).data, coveredText);
      },
    );

    testWidgets(
      'a starving travel line is red with the user phrase (D-04, D-06)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(type: 'hunt'),
          travelPreview: _travelPreview(arrivesAlive: false),
        );

        final line = find.byKey(QuestInfoSheet.travelLineKey);
        expect(tester.widget<Text>(line).data, starvingText);
        expect(_colorOf(tester, line), KlimmeckGuideTheme.bloodRed);
      },
    );

    testWidgets('a covered travel line keeps the body colour (D-04)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(type: 'hunt'),
        travelPreview: _travelPreview(),
      );

      final line = find.byKey(QuestInfoSheet.travelLineKey);
      expect(_colorOf(tester, line), isNot(KlimmeckGuideTheme.bloodRed));
    });

    testWidgets(
      'the travel line sits between the time line and the title line (D-04)',
      (tester) async {
        await _pump(
          tester,
          buildQuest(type: 'hunt', timeToComplete: 60000, minTitle: 'hero'),
          travelPreview: _travelPreview(),
        );

        final timeY = tester
            .getTopLeft(find.textContaining('Tempo richiesto'))
            .dy;
        final travelY = tester
            .getTopLeft(find.byKey(QuestInfoSheet.travelLineKey))
            .dy;
        final titleY = tester.getTopLeft(find.text('Titolo minimo: Eroe')).dy;
        expect(timeY, lessThan(travelY));
        expect(travelY, lessThan(titleY));
      },
    );

    testWidgets('a narrative sheet never shows the travel line (D-04)', (
      tester,
    ) async {
      await _pump(
        tester,
        buildQuest(type: 'story', requiredPoints: 3000),
        travelPreview: _travelPreview(),
      );

      expect(find.byKey(QuestInfoSheet.narrativeFamilyKey), findsOneWidget);
      expect(find.byKey(QuestInfoSheet.travelLineKey), findsNothing);
    });

    testWidgets('a sheet without a preview shows no travel line (D-04)', (
      tester,
    ) async {
      await _pump(tester, buildQuest(type: 'hunt'));

      expect(find.byKey(QuestInfoSheet.combatFamilyKey), findsOneWidget);
      expect(find.byKey(QuestInfoSheet.travelLineKey), findsNothing);
    });
  });

  group('cure rows (BE Phase 18)', () {
    testWidgets(
      'a heal with a cure shows the cure line and the life row on the service sheet (D-03, D-04)',
      (tester) async {
        await _pump(
          tester,
          _cureQuest(),
          characterInjuries: const [InjuryType.contusion],
        );

        final serviceFamily = QuestInfoSheet.serviceFamilyKey;
        expect(
          _inFamily(serviceFamily, QuestInfoSheet.cureLineKey),
          findsOneWidget,
        );
        expect(
          _inFamily(serviceFamily, QuestInfoSheet.lifeLineKey),
          findsOneWidget,
        );
        expect(
          _textOf(tester, QuestInfoSheet.cureLineKey),
          'Cura le tue ferite: contusione',
        );
        expect(
          _textOf(tester, QuestInfoSheet.lifeLineKey),
          'Vita: almeno il 50%',
        );
      },
    );

    testWidgets(
      'the life row elides the article for 80 and keeps it for 50 (D-21)',
      (tester) async {
        const expected = [
          (0.8, "Vita: almeno l'80%"),
          (0.5, 'Vita: almeno il 50%'),
          (1, 'Vita: al massimo'),
        ];
        for (final (share, line) in expected) {
          await _pump(tester, _cureQuest(share: share));

          expect(_textOf(tester, QuestInfoSheet.lifeLineKey), line);
        }
      },
    );

    testWidgets(
      "the cure line lists the viewer's curable injuries in the character's order (D-03)",
      (tester) async {
        await _pump(
          tester,
          _cureQuest(),
          characterInjuries: const [
            InjuryType.deepCut,
            InjuryType.blindness,
            InjuryType.contusion,
          ],
        );

        expect(
          _textOf(tester, QuestInfoSheet.cureLineKey),
          'Cura le tue ferite: taglio profondo, contusione',
        );
      },
    );

    testWidgets('a combat quest with a cure shows the two rows (D-05)', (
      tester,
    ) async {
      await _pump(
        tester,
        _cureQuest(type: 'enemy'),
        characterInjuries: const [InjuryType.contusion],
      );

      final combatFamily = QuestInfoSheet.combatFamilyKey;
      expect(
        _inFamily(combatFamily, QuestInfoSheet.cureLineKey),
        findsOneWidget,
      );
      expect(
        _inFamily(combatFamily, QuestInfoSheet.lifeLineKey),
        findsOneWidget,
      );
    });

    testWidgets('a narrative quest with a cure shows the two rows (D-05)', (
      tester,
    ) async {
      await _pump(
        tester,
        _cureQuest(type: 'story'),
        characterInjuries: const [InjuryType.contusion],
      );

      final narrativeFamily = QuestInfoSheet.narrativeFamilyKey;
      expect(
        _inFamily(narrativeFamily, QuestInfoSheet.cureLineKey),
        findsOneWidget,
      );
      expect(
        _inFamily(narrativeFamily, QuestInfoSheet.lifeLineKey),
        findsOneWidget,
      );
    });

    testWidgets(
      'a narrative quest with a long lore scrolls to the cure rows and keeps '
      'cost and title pinned in landscape (D-05)',
      (tester) async {
        final longLore = [
          for (var i = 0; i < 4; i++)
            {
              'id': 'l-$i',
              'name': 'Cronaca $i',
              'description':
                  'Molto tempo fa, quando le torri di Andogan erano giovani, '
                      'i guaritori del tempio custodivano un patto antico. ' *
                  4,
            },
        ];
        await _pump(
          tester,
          buildQuest(
            type: 'story',
            requiredPoints: 3000,
            minTitle: 'hero',
            lore: longLore,
            prizes: {'cure': questCureJson(share: 0.5)},
          ),
          viewer: buildViewer(twitchPoints: 1200),
          characterInjuries: const [InjuryType.contusion],
        );

        expect(tester.takeException(), isNull);
        final family = find.byKey(QuestInfoSheet.narrativeFamilyKey);
        final scrollRegion = find.descendant(
          of: family,
          matching: find.byType(Scrollable),
        );
        final lifeLine = find.byKey(QuestInfoSheet.lifeLineKey);
        final pinnedLines = [
          find.byKey(QuestInfoSheet.costLineKey),
          find.text('Titolo richiesto: Eroe'),
        ];
        Offset offsetInFamily(Finder line) =>
            tester.getTopLeft(line) - tester.getTopLeft(family);
        final pinnedOffsets = pinnedLines.map(offsetInFamily).toList();
        expect(
          tester.getRect(lifeLine).top,
          greaterThanOrEqualTo(tester.getRect(scrollRegion).bottom),
        );

        await tester.ensureVisible(lifeLine);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.state<ScrollableState>(scrollRegion).position.pixels,
          greaterThan(0),
        );
        expect(
          tester.getRect(lifeLine).overlaps(tester.getRect(scrollRegion)),
          isTrue,
        );
        expect(pinnedLines.map(offsetInFamily).toList(), pinnedOffsets);
        for (final line in pinnedLines) {
          expect(
            tester
                .getRect(family)
                .contains(tester.getBottomRight(line) - const Offset(1, 1)),
            isTrue,
          );
        }
      },
    );

    testWidgets(
      'a job with a cure shows the two rows, a heal without a cure shows neither (D-05)',
      (tester) async {
        await _pump(
          tester,
          _cureQuest(type: 'job'),
          characterInjuries: const [InjuryType.contusion],
        );

        expect(find.byKey(QuestInfoSheet.cureLineKey), findsOneWidget);
        expect(find.byKey(QuestInfoSheet.lifeLineKey), findsOneWidget);

        for (final heal in [
          buildQuest(type: 'heal'),
          buildQuest(type: 'heal', prizes: {}),
        ]) {
          await _pump(
            tester,
            heal,
            characterInjuries: const [InjuryType.contusion],
          );

          expect(find.byKey(QuestInfoSheet.cureLineKey), findsNothing);
          expect(find.byKey(QuestInfoSheet.lifeLineKey), findsNothing);
        }
      },
    );

    testWidgets('with no curable injury only the life row is shown (D-03)', (
      tester,
    ) async {
      await _pump(
        tester,
        _cureQuest(),
        characterInjuries: const [InjuryType.blindness],
      );

      expect(find.byKey(QuestInfoSheet.cureLineKey), findsNothing);
      expect(find.byKey(QuestInfoSheet.lifeLineKey), findsOneWidget);
    });

    testWidgets(
      "without the character's injuries only the life row is shown (D-19)",
      (tester) async {
        await _pump(tester, _cureQuest());

        expect(find.byKey(QuestInfoSheet.cureLineKey), findsNothing);
        expect(find.byKey(QuestInfoSheet.lifeLineKey), findsOneWidget);
      },
    );

    testWidgets(
      'a zero share hides the life row and keeps the cure line (D-04)',
      (tester) async {
        await _pump(
          tester,
          _cureQuest(share: 0),
          characterInjuries: const [InjuryType.contusion],
        );

        expect(find.byKey(QuestInfoSheet.lifeLineKey), findsNothing);
        expect(find.byKey(QuestInfoSheet.cureLineKey), findsOneWidget);
      },
    );

    testWidgets('the cure line sits above the life row (D-03, D-04)', (
      tester,
    ) async {
      await _pump(
        tester,
        _cureQuest(),
        characterInjuries: const [InjuryType.contusion],
      );

      final cureTop = tester.getTopLeft(find.byKey(QuestInfoSheet.cureLineKey));
      final lifeTop = tester.getTopLeft(find.byKey(QuestInfoSheet.lifeLineKey));
      expect(cureTop.dy, lessThan(lifeTop.dy));
    });
  });
}
