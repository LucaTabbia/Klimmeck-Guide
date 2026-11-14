import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/prizes_step.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _horse = 'pet-travel-horse';
const String _cat = 'pet-cat';

Map<String, dynamic> _equipment(String id) =>
    equipmentAssetJson(id: id)['item'] as Map<String, dynamic>;

Map<String, dynamic> _loot(String id) =>
    lootAssetJson(id: id)['item'] as Map<String, dynamic>;

/// Catalogo servito: spada, erba, gatto e palla di fuoco; il blocco porta la
/// reliquia e il cavallo, che la bozza servita ha già precompilato (D-22).
final MissionPrizeOptions _options = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(
    equipment: [_equipment('e-sword')],
    loot: [_loot('l-herb')],
    pets: [catPetJson()],
    spells: [spellJson(id: fireballSpellId, name: 'Palla di fuoco')],
    block: {
      'coins': {'gold': 5, 'silver': 3, 'copper': 1},
      'xp': 400,
      'randomLoot': [
        {'item': _loot('l-relic'), 'quantity': 1},
      ],
      'pet': petJson(),
    },
  ),
)!;

MissionDraft _draftWith(List<Map<String, dynamic>> prizes) =>
    MissionDraft.tryFromJson(missionDraftJson(step: 'prizes', prizes: prizes))!;

/// Premio servito di Aldo: 2 oro, 150 PE, la reliquia e il cavallo.
final MissionDraft _prefilled = _draftWith([
  missionPrizeJson(
    items: [
      {'item': 'l-relic', 'quantity': 1},
    ],
    pet: _horse,
  ),
]);

void main() {
  late MockMissionPrizeOptionsCubit prizeOptionsCubit;
  late List<List<MissionPrizeInput>> sent;

  setUp(() {
    seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      CloudinaryAssets.emptyCardSheet,
    ]);
    prizeOptionsCubit = MockMissionPrizeOptionsCubit();
    sent = [];
    when(() => prizeOptionsCubit.loadAll(any())).thenAnswer((_) async {});
    whenListen(
      prizeOptionsCubit,
      const Stream<MissionPrizeOptionsState>.empty(),
      initialState: MissionPrizeOptionsState(options: {_aldo: _options}),
    );
  });

  Future<void> pumpStep(WidgetTester tester, MissionDraft draft) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BlocProvider<MissionPrizeOptionsCubit>.value(
            value: prizeOptionsCubit,
            child: PrizesStep(
              draft: draft,
              isSubmitting: false,
              onNext: sent.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// La lista della pagina è il primo Scrollable (i campi ne hanno uno loro).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      60,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  String fieldText(WidgetTester tester, Key key) =>
      tester.widget<TextField>(find.byKey(key)).controller!.text;

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(MissionCompletionScreen.nextKey));
    await tester.pump();
  }

  MissionPrizeInput sentPrize() => sent.single.single;

  testWidgets('each character starts from the prefilled served prizes (D-22)', (
    tester,
  ) async {
    await pumpStep(tester, _prefilled);

    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'gold')), '2');
    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'silver')), '0');
    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'copper')), '0');
    expect(fieldText(tester, PrizesStep.xpFieldKeyFor(_aldo)), '150');
    await reveal(tester, find.byType(ItemRow));
    expect(
      tester.widget<ItemRow>(find.byType(ItemRow)).assetItem.id,
      'l-relic',
    );
    await reveal(tester, find.byType(CompanionRow));
    expect(
      tester.widget<CompanionRow>(find.byType(CompanionRow)).pet.id,
      _horse,
    );
  });

  testWidgets('coins and xp are free numbers with no ceiling (D-15)', (
    tester,
  ) async {
    await pumpStep(tester, _prefilled);

    await tester.enterText(
      find.byKey(PrizesStep.coinFieldKeyFor(_aldo, 'gold')),
      '900',
    );
    await tester.enterText(
      find.byKey(PrizesStep.xpFieldKeyFor(_aldo)),
      '12000',
    );
    await tester.enterText(
      find.byKey(PrizesStep.coinFieldKeyFor(_aldo, 'silver')),
      'a5-b',
    );
    await tester.pump();
    await tapNext(tester);

    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'silver')), '5');
    expect(sentPrize().coins, const Coins(gold: 900, silver: 5));
    expect(sentPrize().xp, 12000);
  });

  testWidgets(
    'coins and xp take digits only, at most 7 (BE technical ceiling 9 999 999)',
    (tester) async {
      await pumpStep(tester, _prefilled);

      await tester.enterText(
        find.byKey(PrizesStep.xpFieldKeyFor(_aldo)),
        '123456789',
      );
      await tester.enterText(
        find.byKey(PrizesStep.coinFieldKeyFor(_aldo, 'gold')),
        '99999999999999999999',
      );
      await tester.pump();
      await tapNext(tester);

      expect(fieldText(tester, PrizesStep.xpFieldKeyFor(_aldo)), '1234567');
      expect(sentPrize().xp, 1234567);
      expect(sentPrize().coins.gold, 9999999);
      expect(maxPrizeAmountDigits, 7);
      expect(find.text('7/7'), findsNothing);
    },
  );

  testWidgets('an item quantity stays within 1..99 (D-15)', (tester) async {
    await pumpStep(
      tester,
      _draftWith([
        missionPrizeJson(
          items: [
            {'item': 'l-relic', 'quantity': 1},
            {'item': 'e-sword', 'quantity': 99},
          ],
        ),
      ]),
    );
    await reveal(tester, find.byType(QuantityStepper).last);

    final steppers = tester
        .widgetList<QuantityStepper>(find.byType(QuantityStepper))
        .toList();
    expect([for (final s in steppers) (s.min, s.max)], [(1, 99), (1, 99)]);
    final minus = find.widgetWithIcon(IconButton, Icons.remove);
    final plus = find.widgetWithIcon(IconButton, Icons.add);
    expect(tester.widget<IconButton>(minus.first).onPressed, isNull);
    expect(tester.widget<IconButton>(plus.last).onPressed, isNull);
    await tester.tap(plus.first);
    await tester.pump();
    await tapNext(tester);

    expect(sentPrize().items, const [
      MissionPrizeItem(itemId: 'l-relic', quantity: 2),
      MissionPrizeItem(itemId: 'e-sword', quantity: 99),
    ]);
  });

  testWidgets('items, pet, spell and cure can be removed (D-07, D-22)', (
    tester,
  ) async {
    await pumpStep(
      tester,
      _draftWith([
        missionPrizeJson(
          items: [
            {'item': 'l-relic', 'quantity': 1},
          ],
          pet: _horse,
          spell: fireballSpellId,
          cure: const {'lifePointsShare': 0.5, 'canHeal': <String>[]},
        ),
      ]),
    );
    expect(find.text('Vita: almeno il 50%'), findsOneWidget);

    for (var removed = 0; removed < 4; removed++) {
      final remove = find.byTooltip(PrizesStep.removeTooltip);
      await reveal(tester, remove.first);
      await tester.tap(remove.first);
      await tester.pump();
    }
    await tapNext(tester);

    expect(find.byTooltip(PrizesStep.removeTooltip), findsNothing);
    expect(sentPrize().cure, isFalse);
    expect(sentPrize().items, isEmpty);
    expect(sentPrize().petId, isNull);
    expect(sentPrize().spellId, isNull);
  });

  group('cure of the block (D-22)', () {
    const blockCure = {'lifePointsShare': 0.5, 'canHeal': <String>[]};

    void serveOptionsWithCure() => whenListen(
      prizeOptionsCubit,
      const Stream<MissionPrizeOptionsState>.empty(),
      initialState: MissionPrizeOptionsState(
        options: {
          _aldo: MissionPrizeOptions.tryFromJson(
            missionPrizeOptionsJson(
              block: {'randomLoot': <Object>[], 'cure': blockCure},
            ),
          )!,
        },
      ),
    );

    testWidgets(
      '«Aggiungi cura» puts back the cure of the block after a removal (D-22)',
      (tester) async {
        serveOptionsWithCure();
        await pumpStep(tester, _draftWith([missionPrizeJson(cure: blockCure)]));
        expect(find.byKey(PrizesStep.addCureKeyFor(_aldo)), findsNothing);

        await tester.tap(find.byTooltip(PrizesStep.removeTooltip));
        await tester.pump();
        expect(find.text('Vita: almeno il 50%'), findsNothing);
        await tester.tap(find.byKey(PrizesStep.addCureKeyFor(_aldo)));
        await tester.pump();
        await tapNext(tester);

        expect(find.text('Vita: almeno il 50%'), findsOneWidget);
        expect(find.text(PrizesStep.addCureLabel), findsNothing);
        expect(sentPrize().cure, isTrue);
      },
    );

    testWidgets(
      'a draft saved without the cure offers it back from the block (D-22)',
      (tester) async {
        serveOptionsWithCure();
        await pumpStep(tester, _draftWith([missionPrizeJson()]));

        expect(find.text(PrizesStep.addCureLabel), findsOneWidget);
      },
    );

    testWidgets('a block without a cure offers no «Aggiungi cura» (D-22)', (
      tester,
    ) async {
      await pumpStep(tester, _draftWith([missionPrizeJson()]));

      expect(find.byKey(PrizesStep.addCureKeyFor(_aldo)), findsNothing);
    });
  });

  testWidgets(
    '«Aggiungi premio» adds an item, a pet or a spell from the served catalogue (D-07)',
    (tester) async {
      await pumpStep(tester, _prefilled);

      Future<void> pickFrom(String tab, Finder entry) async {
        await tester.tap(find.byKey(PrizesStep.addPrizeKeyFor(_aldo)));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.byType(PrizeCatalogueSheet), findsNothing);
      }

      await pickFrom(PrizeCatalogueSheet.itemsTab, find.text('Oggetto l-herb'));
      await pickFrom(
        PrizeCatalogueSheet.petsTab,
        find.text('Gatto di bottega'),
      );
      await pickFrom(
        PrizeCatalogueSheet.spellsTab,
        find.text('Palla di fuoco').last,
      );

      await reveal(tester, find.byType(SpellCard));
      expect(find.byType(SpellCard), findsOneWidget);
      await tapNext(tester);

      expect(sentPrize().items, const [
        MissionPrizeItem(itemId: 'l-relic', quantity: 1),
        MissionPrizeItem(itemId: 'l-herb', quantity: 1),
      ]);
      expect(sentPrize().petId, _cat);
      expect(sentPrize().spellId, fireballSpellId);
    },
  );

  testWidgets(
    '«Avanti» to the recap waits while a fight has no verdict (D-24)',
    (tester) async {
      await pumpStep(
        tester,
        MissionDraft.tryFromJson(
          missionDraftJson(
            step: 'prizes',
            fights: [missionFightJson()],
            prizes: [missionPrizeJson()],
          ),
        )!,
      );

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(MissionCompletionScreen.nextKey))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('nothing is built from the served block (D-22)', (tester) async {
    await pumpStep(tester, _draftWith(const []));

    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'gold')), '0');
    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'silver')), '0');
    expect(fieldText(tester, PrizesStep.coinFieldKeyFor(_aldo, 'copper')), '0');
    expect(fieldText(tester, PrizesStep.xpFieldKeyFor(_aldo)), '0');
    expect(find.byType(ItemRow), findsNothing);
    expect(find.byType(CompanionRow), findsNothing);
    await tapNext(tester);

    expect(
      sentPrize(),
      const MissionPrizeInput(
        characterId: _aldo,
        coins: Coins(),
        xp: 0,
        cure: false,
      ),
    );
  });

  testWidgets(
    'names come from the served options; the page reads them once per character',
    (tester) async {
      await pumpStep(tester, _prefilled);

      verify(() => prizeOptionsCubit.loadAll([_aldo])).called(1);
    },
  );

  testWidgets(
    'a failed options read shows the error line and «Riprova» reads again (D-07)',
    (tester) async {
      when(() => prizeOptionsCubit.loadFor(any())).thenAnswer((_) async {});
      whenListen(
        prizeOptionsCubit,
        const Stream<MissionPrizeOptionsState>.empty(),
        initialState: const MissionPrizeOptionsState(
          failures: {_aldo: InnkeeperFailure.connection},
        ),
      );
      await pumpStep(tester, _prefilled);

      expect(
        find.text(MissionCompletionScreen.connectionMessage),
        findsOneWidget,
      );
      await tester.tap(find.byKey(PrizesStep.retryKeyFor(_aldo)));

      verify(() => prizeOptionsCubit.loadFor(_aldo)).called(1);
    },
  );

  testWidgets('a character whose options are loading shows a small loader', (
    tester,
  ) async {
    whenListen(
      prizeOptionsCubit,
      const Stream<MissionPrizeOptionsState>.empty(),
      initialState: const MissionPrizeOptionsState(loading: {_aldo}),
    );
    await pumpStep(tester, _prefilled);

    expect(find.byType(KGLoader), findsOneWidget);
    expect(find.byType(ItemRow), findsNothing);
  });
}
