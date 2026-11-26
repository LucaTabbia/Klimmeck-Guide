import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potionPour/potion_pour_scene.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/healed_injuries_text.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/race_figure_url.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../../helpers/landscape.dart';
import '../../../../../../helpers/mocks.dart';
import '../../../../../../helpers/svg_cache_seed.dart';
import '../../../../../../helpers/test_app.dart';

const Key _openKey = ValueKey('test.openPourScene');
const String _worg = 'pet-worg';
const String _cat = 'pet-cat';

class _MockPotionRecoveryCubit extends MockCubit<PotionRecoveryState>
    implements PotionRecoveryCubit {}

CompanionPotionTarget _target(String id, {String? name, int life = 40}) =>
    CompanionPotionTarget(
      owned: OwnedPet.tryFromJson(
        ownedPetJson(
          pet: petJson(id: id, name: 'Worg', maxLifePoints: 100),
          currentLifePoints: 40,
          name: name,
        ),
      )!,
      life: life,
      maxLifePoints: 100,
    );

Finder _lifeText(Key bar, String value) =>
    find.descendant(of: find.byKey(bar), matching: find.text(value));

void main() {
  final herbs = LootItem.fromJson(healPotionJson());
  final fenrir = _target(_worg, name: 'Fenrir');
  final micio = _target(_cat, name: 'Micio', life: 70);

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
    seedSvgCache(const [
      'main/races/elf_female.svg',
      CloudinaryAssets.arrowMap,
    ]);
  });

  Future<void> pumpScene(
    WidgetTester tester, {
    PotionState state = const PotionIdle(),
    List<CompanionPotionTarget> companions = const [],
    Duration? characterWait,
  }) async {
    useLandscapePhone(tester);
    whenListen(cubit, states.stream, initialState: state);
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
                potionPourRoute(
                  potionCubit: cubit,
                  recoveryCubit: recovery,
                  scene: PotionPourScene(
                    item: herbs,
                    race: RaceType.elf,
                    sex: SexType.female,
                    lifePoints: 4,
                    maxLifePoints: 12,
                    companions: companions,
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> emit(WidgetTester tester, PotionState state) async {
    when(() => cubit.state).thenReturn(state);
    states.add(state);
    await tester.pump();
  }

  /// Trascina la boccetta di [dx] e la tiene lì per [hold].
  Future<TestGesture> dragAndHold(
    WidgetTester tester,
    double dx, {
    Duration hold = const Duration(milliseconds: 1500),
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(PotionPourScene.bottleKey)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(dx / 10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (
      var t = Duration.zero;
      t < hold;
      t += const Duration(milliseconds: 16)
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return gesture;
  }

  /// Fa avanzare i frame finché la boccetta vuota mostra l'esito.
  Future<void> pumpUntilOutcome(WidgetTester tester) async {
    for (var i = 0; i < 600; i++) {
      if (find.byKey(PotionPourScene.outcomeKey).evaluate().isNotEmpty) {
        await tester.pump(PotionPourScene.hpAnimationDuration);
        return;
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('drinkers', () {
    testWidgets('the character stands on the right with the race figure', (
      tester,
    ) async {
      await pumpScene(tester);

      final figure = find.byKey(PotionPourScene.characterKey);
      expect(figure, findsOneWidget);
      expect(
        tester.getCenter(figure).dx,
        greaterThan(tester.getCenter(find.byKey(PotionPourScene.bottleKey)).dx),
      );
      expect(
        tester.widget<PotionDrinkerFigure>(figure).url,
        raceFigureUrl(RaceType.elf, SexType.female),
      );
    });

    testWidgets('a character who must still wait is not shown', (tester) async {
      await pumpScene(
        tester,
        characterWait: const Duration(minutes: 5),
        companions: [fenrir],
      );

      expect(find.byKey(PotionPourScene.characterKey), findsNothing);
    });

    testWidgets('the companions stand on the left, one at a time', (
      tester,
    ) async {
      await pumpScene(tester, companions: [fenrir, micio]);

      final first = find.byKey(PotionPourScene.companionKeyOf(_worg));
      expect(first, findsOneWidget);
      expect(
        tester.getCenter(first).dx,
        lessThan(tester.getCenter(find.byKey(PotionPourScene.bottleKey)).dx),
      );
      expect(find.byKey(PotionPourScene.companionKeyOf(_cat)), findsNothing);
    });

    testWidgets('an arrow down tells there is a next companion, an arrow up '
        'a previous one', (tester) async {
      await pumpScene(tester, companions: [fenrir, micio]);

      expect(find.byKey(PotionPourScene.nextCompanionKey), findsOneWidget);
      expect(find.byKey(PotionPourScene.previousCompanionKey), findsNothing);

      await tester.fling(
        find.byKey(PotionPourScene.companionsKey),
        const Offset(0, -300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(PotionPourScene.nextCompanionKey), findsNothing);
      expect(find.byKey(PotionPourScene.previousCompanionKey), findsOneWidget);
    });

    testWidgets('the drinkers stand centred on their life bars and in the '
        'height above them', (tester) async {
      await pumpScene(tester, companions: [fenrir]);

      final screen = tester.getRect(find.byType(PotionPourScene));
      for (final (figure, bar) in [
        (PotionPourScene.characterKey, PotionPourScene.characterLifeKey),
        (
          PotionPourScene.companionKeyOf(_worg),
          PotionPourScene.companionLifeKey,
        ),
      ]) {
        final figureRect = tester.getRect(find.byKey(figure));
        final barRect = tester.getRect(find.byKey(bar));
        expect(figureRect.center.dx, closeTo(barRect.center.dx, 1));
        expect(
          figureRect.center.dy,
          closeTo((screen.top + barRect.top) / 2, 1),
        );
        expect(figureRect.bottom, lessThanOrEqualTo(barRect.top));
      }
    });

    testWidgets('the arrows overlap neither the companion, its bar nor the '
        'bottle', (tester) async {
      await pumpScene(tester, companions: [fenrir, micio, fenrir]);
      await tester.drag(
        find.byKey(PotionPourScene.companionsKey),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final others = [
        tester.getRect(find.byKey(PotionPourScene.companionKeyOf(_cat))),
        tester.getRect(find.byKey(PotionPourScene.companionLifeKey)),
        tester.getRect(find.byKey(PotionPourScene.bottleKey)),
      ];
      final screen = tester.getRect(find.byType(PotionPourScene));
      final companion = others.first;
      final up = tester.getRect(
        find.byKey(PotionPourScene.previousCompanionKey),
      );
      final down = tester.getRect(find.byKey(PotionPourScene.nextCompanionKey));
      for (final rect in [up, down]) {
        for (final other in others) {
          expect(rect.overlaps(other), isFalse, reason: '$rect vs $other');
        }
        expect(rect.center.dx, closeTo(companion.center.dx, 1));
        expect(rect.top, greaterThanOrEqualTo(screen.top));
      }
      expect(up.bottom, lessThanOrEqualTo(companion.top));
      expect(down.top, greaterThanOrEqualTo(companion.bottom));
    });

    testWidgets('the arrow above stays below the status bar', (tester) async {
      tester.view.padding = const FakeViewPadding(top: 90);
      await pumpScene(tester, companions: [fenrir, micio, fenrir]);
      await tester.drag(
        find.byKey(PotionPourScene.companionsKey),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final up = tester.getRect(
        find.byKey(PotionPourScene.previousCompanionKey),
      );
      expect(up.top, greaterThanOrEqualTo(30));
    });

    testWidgets('a companion scrolled away leaves the screen, not the status '
        'bar line', (tester) async {
      tester.view.padding = const FakeViewPadding(top: 90);
      await pumpScene(tester, companions: [fenrir, micio]);

      final pager = tester.getRect(find.byKey(PotionPourScene.companionsKey));
      expect(pager.top, 0);
      final figure = tester.getRect(
        find.byKey(PotionPourScene.companionKeyOf(_worg)),
      );
      expect(figure.top, greaterThanOrEqualTo(30));
    });

    testWidgets('a single companion shows no arrow', (tester) async {
      await pumpScene(tester, companions: [fenrir]);

      expect(find.byKey(PotionPourScene.nextCompanionKey), findsNothing);
      expect(find.byKey(PotionPourScene.previousCompanionKey), findsNothing);
    });

    testWidgets('a life bar stands under the character', (tester) async {
      await pumpScene(tester);

      expect(
        _lifeText(PotionPourScene.characterLifeKey, '4 / 12'),
        findsOneWidget,
      );
      expect(find.byKey(PotionPourScene.companionLifeKey), findsNothing);
    });

    testWidgets('one companion life bar follows the scroll', (tester) async {
      await pumpScene(tester, companions: [fenrir, micio]);

      expect(
        _lifeText(PotionPourScene.companionLifeKey, '40 / 100'),
        findsOneWidget,
      );

      await tester.fling(
        find.byKey(PotionPourScene.companionsKey),
        const Offset(0, -300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(PotionPourScene.companionLifeKey), findsOneWidget);
      expect(
        _lifeText(PotionPourScene.companionLifeKey, '70 / 100'),
        findsOneWidget,
      );
    });

    testWidgets('a character who must still wait has no life bar', (
      tester,
    ) async {
      await pumpScene(
        tester,
        characterWait: const Duration(minutes: 5),
        companions: [fenrir],
      );

      expect(find.byKey(PotionPourScene.characterLifeKey), findsNothing);
    });

    testWidgets('with no companion the left side is empty', (tester) async {
      await pumpScene(tester);

      expect(find.byKey(PotionPourScene.companionsKey), findsNothing);
    });
  });

  group('pour', () {
    testWidgets('tilting toward the character pours it into him once', (
      tester,
    ) async {
      await pumpScene(tester, companions: [fenrir]);

      final gesture = await dragAndHold(tester, 420);
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      verify(() => cubit.drink(herbs.id)).called(1);
      verifyNever(
        () => cubit.give(
          any(),
          petId: any(named: 'petId'),
          targetName: any(named: 'targetName'),
        ),
      );
    });

    testWidgets('tilting toward the companion gives it the potion', (
      tester,
    ) async {
      await pumpScene(tester, companions: [fenrir]);

      final gesture = await dragAndHold(tester, -420);
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      verify(
        () => cubit.give(herbs.id, petId: _worg, targetName: 'Fenrir'),
      ).called(1);
      verifyNever(() => cubit.drink(any()));
    });

    testWidgets('the companion scrolled into view is the one who drinks', (
      tester,
    ) async {
      await pumpScene(tester, companions: [fenrir, micio]);

      await tester.fling(
        find.byKey(PotionPourScene.companionsKey),
        const Offset(0, -300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(PotionPourScene.companionKeyOf(_cat)), findsOneWidget);

      final gesture = await dragAndHold(tester, -420);
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      verify(
        () => cubit.give(herbs.id, petId: _cat, targetName: 'Micio'),
      ).called(1);
    });

    testWidgets('a small tilt released before the first drop pours nothing', (
      tester,
    ) async {
      await pumpScene(tester, companions: [fenrir]);

      final gesture = await dragAndHold(
        tester,
        60,
        hold: const Duration(milliseconds: 300),
      );
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));

      verifyNever(() => cubit.drink(any()));
      expect(find.byKey(PotionPourScene.bottleKey), findsOneWidget);
    });

    testWidgets('toward an empty side the bottle never pours', (tester) async {
      await pumpScene(
        tester,
        characterWait: const Duration(minutes: 5),
        companions: [fenrir],
      );

      final gesture = await dragAndHold(tester, 420);
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));

      verifyNever(() => cubit.drink(any()));
    });
  });

  group('details', () {
    testWidgets('the details are shown from the start with the dark text '
        'outline', (tester) async {
      await pumpScene(tester);

      final details = find.byKey(PotionPourScene.detailsKey);
      final cure = tester.widget<HealedInjuriesText>(
        find.descendant(of: details, matching: find.byType(HealedInjuriesText)),
      );
      expect(cure.style?.shadows, KlimmeckGuideTheme.bordersForText);
      final recovery = tester.widget<Text>(
        find.descendant(of: details, matching: find.text('Ricarica: 30 min')),
      );
      expect(recovery.style?.shadows, KlimmeckGuideTheme.bordersForText);
    });

    testWidgets('the details leave room to the outcome once the potion '
        'pours', (tester) async {
      await pumpScene(tester);

      final gesture = await dragAndHold(tester, 420);
      await gesture.up();

      expect(find.byKey(PotionPourScene.detailsKey), findsNothing);
    });
  });

  group('leaving', () {
    testWidgets('a tap away from the bottle puts it back', (tester) async {
      await pumpScene(tester);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byType(PotionPourScene), findsNothing);
    });

    testWidgets('a tap on the character or on the companion puts the bottle '
        'back too', (tester) async {
      for (final drinker in [
        PotionPourScene.characterKey,
        PotionPourScene.companionKeyOf(_worg),
      ]) {
        await pumpScene(tester, companions: [fenrir]);

        await tester.tapAt(tester.getCenter(find.byKey(drinker)));
        await tester.pumpAndSettle();

        expect(find.byType(PotionPourScene), findsNothing, reason: '$drinker');
      }
    });

    testWidgets('while the potion is in flight a tap does not close', (
      tester,
    ) async {
      await pumpScene(tester, state: PotionDrinking(herbs.id));

      await tester.tapAt(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PotionPourScene), findsOneWidget);
    });

    testWidgets('a refusal closes the scene', (tester) async {
      await pumpScene(tester);

      await emit(
        tester,
        PotionRefused(herbs.id, ItemUseFailure.unknown, sequence: 1),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PotionPourScene), findsNothing);
    });
  });

  group('outcome', () {
    Future<void> pourAndDrink(WidgetTester tester) async {
      final gesture = await dragAndHold(tester, 420);
      await gesture.up();
      await emit(
        tester,
        PotionDrunk(herbs.id, UseItemResult.fromJson(useItemResultJson())),
      );
      await pumpUntilOutcome(tester);
    }

    testWidgets('the outcome lines sit on a Material, with no debug '
        'underline, and carry the dark outline; the life bar sits on '
        'parchment', (tester) async {
      await pumpScene(tester);

      await pourAndDrink(tester);

      expect(
        find.ancestor(
          of: find.byKey(PotionPourScene.outcomeKey),
          matching: find.byType(Material),
        ),
        findsWidgets,
      );
      final strip = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(PotionPourScene.characterLifeKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (strip.decoration as BoxDecoration).color,
        KlimmeckGuideTheme.parchment,
      );
      final healed = tester.widget<Text>(find.byKey(PotionPourScene.healedKey));
      expect(healed.style?.shadows, KlimmeckGuideTheme.bordersForText);
    });

    testWidgets("a companion's potion fills the companion bar", (tester) async {
      await pumpScene(tester, companions: [fenrir]);

      final gesture = await dragAndHold(tester, -420);
      await gesture.up();
      await emit(
        tester,
        PotionDrunk(
          herbs.id,
          UseItemResult.fromJson(useItemResultJson()),
          targetPetId: _worg,
          targetName: 'Fenrir',
        ),
      );
      await pumpUntilOutcome(tester);

      expect(
        _lifeText(PotionPourScene.companionLifeKey, '8 / 100'),
        findsOneWidget,
      );
      expect(find.byKey(PotionPourScene.healedKey), findsNothing);
    });

    testWidgets('the outcome closes by itself a little after the life bar '
        'fills', (tester) async {
      await pumpScene(tester);

      await pourAndDrink(tester);
      expect(find.byKey(PotionPourScene.outcomeKey), findsOneWidget);

      await tester.pump(PotionPourScene.outcomeCloseDelay);
      await tester.pumpAndSettle();

      expect(find.byType(PotionPourScene), findsNothing);
    });

    testWidgets('once the bottle is empty the life bar fills and a tap '
        'closes', (tester) async {
      await pumpScene(tester);

      final gesture = await dragAndHold(tester, 420);
      await gesture.up();
      await emit(
        tester,
        PotionDrunk(herbs.id, UseItemResult.fromJson(useItemResultJson())),
      );
      await pumpUntilOutcome(tester);

      expect(
        _lifeText(PotionPourScene.characterLifeKey, '8 / 12'),
        findsOneWidget,
      );
      expect(find.byKey(PotionPourScene.healedKey), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(PotionPourScene), findsNothing);
    });
  });
}
