import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potion_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

const String _herb = 'l-herb';
const Key _openKey = ValueKey('test.openPotionSheet');

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

  late MockPotionCubit cubit;
  late StreamController<PotionState> states;

  setUp(() {
    cubit = MockPotionCubit();
    states = StreamController<PotionState>.broadcast();
    addTearDown(states.close);
    when(() => cubit.drink(any())).thenAnswer((_) async {});
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required PotionState state,
    Stream<PotionState>? stream,
    LootItem? item,
    int maxLifePoints = 12,
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, stream ?? states.stream, initialState: state);
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: _openKey,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider<PotionCubit>.value(
                    value: cubit,
                    child: Scaffold(
                      body: PotionSheet(
                        item: item ?? herbs,
                        maxLifePoints: maxLifePoints,
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
    await pumpSheet(
      tester,
      state: PotionDrunk(_herb, result),
      maxLifePoints: 0,
    );

    expect(find.byKey(PotionSheet.hpKey), findsNothing);
    expect(find.byType(HpDeltaBar), findsNothing);
    expect(find.text('Guarite: contusione'), findsOneWidget);
    expect(find.byKey(PotionSheet.loreKeyOf('lore-limit')), findsOneWidget);
    expect(find.byKey(PotionSheet.continueKey), findsOneWidget);
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
}
