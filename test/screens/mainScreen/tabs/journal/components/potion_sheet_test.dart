import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potion_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

const String _herb = 'l-herb';
const Key _openKey = ValueKey('test.openPotionSheet');
const String _worg = 'pet-worg';
const String _greyWorg = 'pet-grey-worg';

class _MockPotionRecoveryCubit extends MockCubit<PotionRecoveryState>
    implements PotionRecoveryCubit {}

CompanionPotionTarget _target(String id, {String? name}) =>
    CompanionPotionTarget(
      owned: OwnedPet.tryFromJson(
        ownedPetJson(
          pet: petJson(
            id: id,
            name: 'Worg',
            speedModifier: null,
            maxLifePoints: 100,
          ),
          currentLifePoints: 40,
          name: name,
        ),
      )!,
      life: 40,
      maxLifePoints: 100,
    );

void main() {
  final herbs = LootItem.fromJson(healPotionJson());
  final result = UseItemResult.fromJson(
    useItemResultJson(
      loreUnlocked: [
        loreRefJson(
          id: 'lore-limit',
          name: 'Il limite del corpo',
          type: 'knowledge',
        ),
      ],
    ),
  );

  final fenrir = _target(_worg, name: 'Fenrir');
  final greyWorg = _target(_greyWorg);

  late MockPotionCubit cubit;
  late _MockPotionRecoveryCubit recovery;
  late StreamController<PotionState> states;

  setUp(() {
    cubit = MockPotionCubit();
    recovery = _MockPotionRecoveryCubit();
    states = StreamController<PotionState>.broadcast();
    addTearDown(states.close);
    when(() => cubit.drink(any())).thenAnswer((_) async {});
    when(
      () => cubit.give(
        any(),
        petId: any(named: 'petId'),
        targetName: any(named: 'targetName'),
      ),
    ).thenAnswer((_) async {});
    seedSvgCache([CloudinaryAssets.emptyCardSheet]);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required PotionState state,
    Stream<PotionState>? stream,
    LootItem? item,
    int? maxLifePoints = 12,
    List<CompanionPotionTarget> targets = const [],
    Duration? characterWait,
    List<InjuryType>? injuriesBeyondCure,
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, stream ?? states.stream, initialState: state);
    whenListen(
      recovery,
      const Stream<PotionRecoveryState>.empty(),
      initialState: PotionRecoveryState(characterWait),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: _openKey,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider<PotionCubit>.value(value: cubit),
                      BlocProvider<PotionRecoveryCubit>.value(value: recovery),
                    ],
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: injuriesBeyondCure == null
                            ? PotionSheet(
                                item: item ?? herbs,
                                maxLifePoints: maxLifePoints,
                                targets: targets,
                              )
                            : PotionSheet(
                                item: item ?? herbs,
                                maxLifePoints: maxLifePoints,
                                targets: targets,
                                injuriesBeyondCure: injuriesBeyondCure,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, PotionState state) async {
    when(() => cubit.state).thenReturn(state);
    states.add(state);
    await tester.pumpAndSettle();
  }

  TextButton buttonOf(WidgetTester tester, Key key) =>
      tester.widget<TextButton>(find.byKey(key));

  GestureDetector targetOf(WidgetTester tester, String petId) => tester
      .widget<GestureDetector>(find.byKey(PotionSheet.targetKeyOf(petId)));

  testWidgets(
    "the potion sheet leaves the character's innkeeper wounds out of Cura (D-15)",
    (tester) async {
      await pumpSheet(
        tester,
        state: const PotionIdle(),
        item: LootItem.fromJson(
          healPotionJson(canHeal: const ['contusion', 'deepCut']),
        ),
        injuriesBeyondCure: const [InjuryType.deepCut],
      );

      expect(find.text('Cura: contusione'), findsOneWidget);
      expect(find.text('Ricarica: 30 min'), findsOneWidget);
    },
  );

  testWidgets('without innkeeper wounds the sheet shows the whole line', (
    tester,
  ) async {
    final potion = LootItem.fromJson(
      healPotionJson(canHeal: const ['contusion', 'deepCut']),
    );
    await pumpSheet(
      tester,
      state: const PotionIdle(),
      item: potion,
      injuriesBeyondCure: const [],
    );

    expect(find.text(healedInjuriesLine(potion)!), findsOneWidget);
    expect(healedInjuriesLine(potion), contains('taglio profondo'));
  });

  testWidgets(
    'asks Bevi <nome>? with the Cura and Ricarica lines and the two actions (D-18)',
    (tester) async {
      await pumpSheet(tester, state: const PotionIdle());

      expect(find.text('Bevi Erbe da campo?'), findsOneWidget);
      expect(find.text('Cura: contusione'), findsOneWidget);
      expect(find.text('Ricarica: 30 min'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(PotionSheet.drinkKey),
          matching: find.text('Bevi'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(PotionSheet.notNowKey),
          matching: find.text('Non ora'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Bevi calls drink with the item id (D-11)', (tester) async {
    await pumpSheet(tester, state: const PotionIdle());

    await tester.tap(find.byKey(PotionSheet.drinkKey));
    await tester.pump();

    verify(() => cubit.drink(_herb)).called(1);
  });

  testWidgets('Non ora closes the sheet without a call (D-18)', (tester) async {
    await pumpSheet(tester, state: const PotionIdle());

    await tester.tap(find.byKey(PotionSheet.notNowKey));
    await tester.pumpAndSettle();

    expect(find.byType(PotionSheet), findsNothing);
    verifyNever(() => cubit.drink(any()));
  });

  testWidgets(
    'while drinking both actions are disabled and no spinner is shown (D-11)',
    (tester) async {
      await pumpSheet(tester, state: const PotionDrinking(_herb));

      expect(buttonOf(tester, PotionSheet.drinkKey).onPressed, isNull);
      expect(buttonOf(tester, PotionSheet.notNowKey).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PotionSheet), findsOneWidget);
    },
  );

  testWidgets(
    'after the drink the same sheet shows the HP gain, Guarite and the lore line (D-18)',
    (tester) async {
      await pumpSheet(tester, state: PotionDrunk(_herb, result));

      final bar = tester.widget<HpDeltaBar>(find.byKey(PotionSheet.hpKey));
      expect(bar.isGain, isTrue);
      expect(bar.max, 12);
      expect(bar.hp, 8);
      expect(find.text('Guarite: contusione'), findsOneWidget);
      expect(find.byKey(PotionSheet.loreKeyOf('lore-limit')), findsOneWidget);
      expect(
        find.text('Conoscenza appresa: Il limite del corpo'),
        findsOneWidget,
      );
      expect(find.byKey(PotionSheet.drinkKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(PotionSheet.continueKey),
          matching: find.text('Continua'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('no Guarite and no lore line when the result has none (D-18)', (
    tester,
  ) async {
    final bare = UseItemResult.fromJson(
      useItemResultJson(injuriesHealed: const []),
    );

    await pumpSheet(tester, state: PotionDrunk(_herb, bare));

    expect(find.byKey(PotionSheet.hpKey), findsOneWidget);
    expect(find.byKey(PotionSheet.healedKey), findsNothing);
    expect(find.textContaining('Guarite'), findsNothing);
    expect(find.textContaining('Conoscenza appresa'), findsNothing);
  });

  testWidgets('without a positive maximum life the outcome shows no HP bar '
      'but keeps Guarite and the lore line (D-18)', (tester) async {
    for (final maxLifePoints in [null, 0]) {
      await pumpSheet(
        tester,
        state: PotionDrunk(_herb, result),
        maxLifePoints: maxLifePoints,
      );

      final reason = '$maxLifePoints';
      expect(find.byKey(PotionSheet.hpKey), findsNothing, reason: reason);
      expect(find.byType(HpDeltaBar), findsNothing, reason: reason);
      expect(find.text('Guarite: contusione'), findsOneWidget, reason: reason);
      expect(
        find.byKey(PotionSheet.loreKeyOf('lore-limit')),
        findsOneWidget,
        reason: reason,
      );
      expect(
        find.byKey(PotionSheet.continueKey),
        findsOneWidget,
        reason: reason,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Continua closes the sheet (D-18)', (tester) async {
    await pumpSheet(tester, state: PotionDrunk(_herb, result));

    await tester.tap(find.byKey(PotionSheet.continueKey));
    await tester.pumpAndSettle();

    expect(find.byType(PotionSheet), findsNothing);
  });

  testWidgets('a refusal closes the sheet (D-18)', (tester) async {
    await pumpSheet(tester, state: const PotionDrinking(_herb));

    await emit(
      tester,
      const PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 1),
    );

    expect(find.byType(PotionSheet), findsNothing);
  });

  testWidgets('the outcome of another item is not shown (D-18)', (
    tester,
  ) async {
    await pumpSheet(tester, state: PotionDrunk('l-other', result));

    expect(find.text('Bevi Erbe da campo?'), findsOneWidget);
    expect(find.byKey(PotionSheet.drinkKey), findsOneWidget);
    expect(find.byKey(PotionSheet.hpKey), findsNothing);
    expect(find.byKey(PotionSheet.continueKey), findsNothing);
  });

  testWidgets('the two actions are at least 44 px tall (D-18)', (tester) async {
    await pumpSheet(tester, state: const PotionIdle());

    for (final key in [PotionSheet.drinkKey, PotionSheet.notNowKey]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key');
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key');
    }
  });

  group('companion targets (D-08)', () {
    testWidgets('with no eligible companion the sheet is today\'s (D-08)', (
      tester,
    ) async {
      await pumpSheet(tester, state: const PotionIdle());

      expect(find.textContaining('Dai a'), findsNothing);
      expect(find.byKey(PotionSheet.characterWaitKey), findsNothing);
      expect(buttonOf(tester, PotionSheet.drinkKey).onPressed, isNotNull);
    });

    testWidgets('one «Dai a <nome>» parchment per eligible companion '
        '(D-08, D-20)', (tester) async {
      await pumpSheet(
        tester,
        state: const PotionIdle(),
        targets: [fenrir, greyWorg],
      );

      expect(find.byKey(PotionSheet.targetKeyOf(_worg)), findsOneWidget);
      expect(find.byKey(PotionSheet.targetKeyOf(_greyWorg)), findsOneWidget);
      expect(find.text('Dai a Fenrir'), findsOneWidget);
      expect(find.text('Dai a Worg'), findsOneWidget);
      expect(find.text('Vita: 40 / 100'), findsNWidgets(2));
      for (final petId in [_worg, _greyWorg]) {
        final size = tester.getSize(find.byKey(PotionSheet.targetKeyOf(petId)));
        expect(size.height, greaterThanOrEqualTo(44), reason: petId);
      }
    });

    testWidgets('tapping a companion parchment gives the potion to it (D-07)', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        state: const PotionIdle(),
        targets: [fenrir, greyWorg],
      );

      await tester.ensureVisible(find.byKey(PotionSheet.targetKeyOf(_worg)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PotionSheet.targetKeyOf(_worg)));
      await tester.pump();

      verify(
        () => cubit.give(_herb, petId: _worg, targetName: 'Fenrir'),
      ).called(1);
      verifyNever(() => cubit.drink(any()));
    });

    testWidgets('«Bevi» is disabled with the countdown during the character\'s '
        'wait (D-32)', (tester) async {
      await pumpSheet(
        tester,
        state: const PotionIdle(),
        targets: [fenrir],
        characterWait: const Duration(minutes: 72),
      );

      expect(buttonOf(tester, PotionSheet.drinkKey).onPressed, isNull);
      expect(buttonOf(tester, PotionSheet.notNowKey).onPressed, isNotNull);
      expect(
        tester.widget<Text>(find.byKey(PotionSheet.characterWaitKey)).data,
        'pronta fra 1 h 12 min',
      );
      expect(targetOf(tester, _worg).onTap, isNotNull);
    });

    testWidgets('targets and «Bevi» are disabled while the potion is in flight '
        '(single-flight)', (tester) async {
      await pumpSheet(
        tester,
        state: const PotionDrinking(
          _herb,
          targetPetId: _worg,
          targetName: 'Fenrir',
        ),
        targets: [fenrir, greyWorg],
      );

      expect(buttonOf(tester, PotionSheet.drinkKey).onPressed, isNull);
      expect(targetOf(tester, _worg).onTap, isNull);
      expect(targetOf(tester, _greyWorg).onTap, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a target in flight is announced as a disabled button '
        '(single-flight)', (tester) async {
      await pumpSheet(
        tester,
        state: const PotionDrinking(
          _herb,
          targetPetId: _worg,
          targetName: 'Fenrir',
        ),
        targets: [fenrir],
      );

      expect(
        tester.getSemantics(find.byKey(PotionSheet.targetKeyOf(_worg))),
        containsSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
    });

    testWidgets('the outcome face of a companion shows its name and its life '
        'bar (D-08)', (tester) async {
      await pumpSheet(
        tester,
        state: PotionDrunk(
          _herb,
          result,
          targetPetId: _worg,
          targetName: 'Fenrir',
        ),
        targets: [fenrir],
      );

      expect(find.text('Fenrir'), findsOneWidget);
      expect(find.text('Erbe da campo'), findsNothing);
      final bar = tester.widget<HpDeltaBar>(find.byKey(PotionSheet.hpKey));
      expect(bar.max, 100);
      expect(find.byKey(PotionSheet.healedKey), findsNothing);
      expect(find.byKey(PotionSheet.continueKey), findsOneWidget);
    });
  });
}
