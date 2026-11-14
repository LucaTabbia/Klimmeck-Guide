import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_scope.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/companion_content.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/owned_companion_row.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/sections/companion_section.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/haptic_recorder.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

const _horse = 'pet-travel-horse';
const _cat = 'pet-cat';
const _lightImpact = 'HapticFeedbackType.lightImpact';
final _t0 = DateTime.utc(2026, 11, 14, 10);

Character _character({
  String? equipped = _horse,
  bool owning = true,
  List<Map<String, dynamic>>? owned,
  Map<String, dynamic>? activeTravel,
  bool? missionInProgress,
}) => Character.fromJson({
  ...travellingCharacterJson(
    activeTravel: activeTravel,
    missionInProgress: missionInProgress,
  ),
  'assets': {
    'pet': switch (equipped) {
      _horse => petJson(),
      _cat => catPetJson(),
      _ => null,
    },
    'ownedPets':
        owned ??
        (owning
            ? [ownedPetJson(pet: petJson()), ownedPetJson(pet: catPetJson())]
            : const []),
  },
});

Finder _slotBox() => find.byKey(const ValueKey('companion-slot-box'));

Finder _slotCard(String petId) => find.byKey(ValueKey('companion-slot-$petId'));

Finder _ownedPet(String petId) => find.byKey(ValueKey('owned-pet-$petId'));

Finder _xpLine(String petId) => find.byKey(ValueKey('companion-xp-$petId'));

Finder _lifeLine(String petId) => find.byKey(ValueKey('companion-life-$petId'));

Finder _statusLine(String petId) =>
    find.byKey(ValueKey('companion-status-$petId'));

Finder _inSlot(Finder matching) =>
    find.descendant(of: _slotBox(), matching: matching);

Finder _inRow(String petId, Finder matching) =>
    find.descendant(of: _ownedPet(petId), matching: matching);

CompanionCard _cardOf(WidgetTester tester, Finder scope) =>
    tester.widget<CompanionCard>(
      find.descendant(of: scope, matching: find.byType(CompanionCard)),
    );

void main() {
  late MockCharacterCubit characterCubit;
  late MockCompanionCubit companionCubit;
  late FakeServerClockService clock;
  late List<String> detailsAsked;

  setUpAll(() => registerFallbackValue(_character()));

  void stubToggle(CompanionToggleIntent intent) =>
      when(() => companionCubit.toggle(any(), any())).thenReturn(intent);

  setUp(() {
    characterCubit = MockCharacterCubit();
    companionCubit = MockCompanionCubit();
    clock = FakeServerClockService(_t0);
    detailsAsked = [];
    stubToggle(CompanionToggleIntent.equip);
    seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
      CloudinaryAssets.arrowDown,
    ]);
  });

  Future<Character> pump(
    WidgetTester tester, {
    Character? character,
    CompanionState companion = const CompanionState(),
    bool open = true,
  }) async {
    final shown = character ?? _character();
    useLandscapePhone(tester);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(shown),
    );
    whenListen(
      companionCubit,
      const Stream<CompanionState>.empty(),
      initialState: companion,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: RepositoryProvider<ServerClockService>.value(
          value: clock,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<CompanionCubit>.value(value: companionCubit),
            ],
            child: CompanionVitalityScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CompanionSection(
                    size: 60,
                    onShowDetails: detailsAsked.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (open) {
      await tester.tap(find.text('Compagno'));
      await tester.pumpAndSettle();
    }
    return shown;
  }

  Future<void> tapCard(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('is a dropdown titled «Compagno» like the spells (D-17)', (
    tester,
  ) async {
    await pump(tester, open: false);

    expect(find.byType(Dropdown), findsOneWidget);
    expect(find.text('Compagno'), findsOneWidget);
    expect(find.textContaining('Cavalcatura'), findsNothing);
    expect(_ownedPet(_cat).hitTestable(), findsNothing);

    await tester.tap(find.text('Compagno'));
    await tester.pumpAndSettle();

    expect(_ownedPet(_cat).hitTestable(), findsOneWidget);
  });

  testWidgets('the slot holds the equipped companion with its speed (D-10)', (
    tester,
  ) async {
    await pump(tester);

    expect(_cardOf(tester, _slotBox()).pet.id, _horse);
    expect(_inSlot(find.text('Velocità ×2')), findsOneWidget);
    expect(find.byType(CoinsDisplay), findsNothing);
  });

  testWidgets('the slot is an empty box when none is equipped (D-10)', (
    tester,
  ) async {
    await pump(tester, character: _character(equipped: null));

    expect(_slotBox(), findsOneWidget);
    expect(_inSlot(find.byType(CompanionCard)), findsNothing);
  });

  testWidgets(
    'lists the owned companions on cards, the equipped one bookmarked (D-17)',
    (tester) async {
      await pump(tester);

      expect(_ownedPet(_horse), findsOneWidget);
      expect(_ownedPet(_cat), findsOneWidget);
      expect(_cardOf(tester, _ownedPet(_horse)).isMarked, isTrue);
      expect(_cardOf(tester, _ownedPet(_cat)).isMarked, isFalse);
      expect(_inRow(_horse, find.text(companionEquippedMark)), findsOneWidget);
      expect(_inRow(_cat, find.text(companionEquippedMark)), findsNothing);
    },
  );

  testWidgets('tapping an owned card equips it with a light impact (D-17)', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    final character = await pump(tester);

    await tapCard(tester, _ownedPet(_cat));

    verify(() => companionCubit.toggle(character, _cat)).called(1);
    expect(haptics, [_lightImpact]);
  });

  testWidgets('tapping the companion in the slot unequips it (D-17)', (
    tester,
  ) async {
    stubToggle(CompanionToggleIntent.unequip);
    final haptics = recordHaptics(tester);
    final character = await pump(tester);

    await tapCard(tester, _slotCard(_horse));

    verify(() => companionCubit.toggle(character, _horse)).called(1);
    expect(haptics, [_lightImpact]);
  });

  testWidgets('tapping the bookmarked row unequips it (D-10)', (tester) async {
    stubToggle(CompanionToggleIntent.unequip);
    final character = await pump(tester);

    await tapCard(tester, _ownedPet(_horse));

    verify(() => companionCubit.toggle(character, _horse)).called(1);
  });

  testWidgets('a tap while an operation is pending gives no haptic (IN-04)', (
    tester,
  ) async {
    stubToggle(CompanionToggleIntent.ignoredPending);
    final haptics = recordHaptics(tester);
    final character = await pump(tester);

    await tapCard(tester, _ownedPet(_cat));

    verify(() => companionCubit.toggle(character, _cat)).called(1);
    expect(haptics, isEmpty);
  });

  testWidgets('the slot shows the pending companion at once, dimmed (D-10)', (
    tester,
  ) async {
    await pump(
      tester,
      companion: const CompanionState(
        pending: PendingCompanion(
          petId: _cat,
          operation: CompanionOperation.equip,
        ),
      ),
    );

    expect(_cardOf(tester, _slotBox()).pet.id, _cat);
    expect(_inSlot(find.text('Cavallo da viaggio')), findsNothing);
    final dim = tester.widget<AnimatedOpacity>(
      _inSlot(find.byType(AnimatedOpacity)),
    );
    expect(dim.opacity, KlimmeckGuideTheme.pendingInkOpacity);
    expect(_cardOf(tester, _ownedPet(_cat)).isMarked, isTrue);
  });

  testWidgets('a pending unequip empties the slot at once (D-10)', (
    tester,
  ) async {
    await pump(
      tester,
      companion: const CompanionState(
        pending: PendingCompanion(
          petId: _horse,
          operation: CompanionOperation.unequip,
        ),
      ),
    );

    expect(_inSlot(find.byType(CompanionCard)), findsNothing);
    expect(_cardOf(tester, _ownedPet(_horse)).isMarked, isFalse);
  });

  testWidgets('reads «$noOwnedCompanionsLine» when nothing is owned (D-15)', (
    tester,
  ) async {
    await pump(tester, character: _character(equipped: null, owning: false));

    expect(find.text(noOwnedCompanionsLine), findsOneWidget);
    expect(find.byType(OwnedCompanionRow), findsNothing);
    expect(_slotBox(), findsOneWidget);
  });

  testWidgets('stays interactive during a travel (D-10)', (tester) async {
    final character = await pump(
      tester,
      character: _character(activeTravel: activeTravelJson()),
    );
    expect(character.status?.activeTravel, isNotNull);

    await tapCard(tester, _ownedPet(_cat));

    verify(() => companionCubit.toggle(character, _cat)).called(1);
  });

  group('companion experience (BE Phase 19)', () {
    Map<String, dynamic> trainedHorse() =>
        ownedPetJson(pet: petJson(maxXp: 300), xp: 40);

    Map<String, dynamic> newCat() =>
        ownedPetJson(pet: {...catPetJson(), 'maxXp': 100});

    testWidgets(
      'the owned row shows the experience over the catalogue maximum (D-03)',
      (tester) async {
        await pump(
          tester,
          character: _character(equipped: null, owned: [trainedHorse()]),
        );

        expect(
          tester.widget<Text>(_xpLine(_horse)).data,
          'Esperienza: 40 / 300',
        );
      },
    );

    testWidgets('every owned row has its own experience line (D-03)', (
      tester,
    ) async {
      await pump(
        tester,
        character: _character(
          equipped: null,
          owned: [trainedHorse(), newCat()],
        ),
      );

      expect(_inRow(_horse, find.text('Esperienza: 40 / 300')), findsOneWidget);
      expect(tester.widget<Text>(_xpLine(_cat)).data, 'Esperienza: 0 / 100');
      expect(_inRow(_cat, _xpLine(_cat)), findsOneWidget);
    });

    testWidgets(
      'the companion at the side shows the mark and the experience (D-03)',
      (tester) async {
        await pump(tester, character: _character(owned: [trainedHorse()]));

        final mark = _inRow(_horse, find.text(companionEquippedMark));
        final line = _inRow(_horse, _xpLine(_horse));
        expect(mark, findsOneWidget);
        expect(line, findsOneWidget);
        expect(
          tester.getTopLeft(mark).dy,
          lessThan(tester.getTopLeft(line).dy),
        );
      },
    );

    testWidgets('no experience line while maxXp is not served (D-15)', (
      tester,
    ) async {
      final character = await pump(
        tester,
        character: _character(
          equipped: null,
          owned: [ownedPetJson(pet: petJson())],
        ),
      );

      expect(_ownedPet(_horse), findsOneWidget);
      expect(_xpLine(_horse), findsNothing);
      expect(find.textContaining('Esperienza'), findsNothing);

      await tapCard(tester, _ownedPet(_horse));

      verify(() => companionCubit.toggle(character, _horse)).called(1);
    });

    testWidgets(
      'the life of the owned companion is shown under its experience (D-09)',
      (tester) async {
        await pump(
          tester,
          character: _character(
            equipped: null,
            owned: [
              ownedPetJson(
                pet: petJson(maxXp: 300, maxLifePoints: 12),
                xp: 40,
                currentLifePoints: 7,
              ),
            ],
          ),
        );

        expect(tester.widget<Text>(_lifeLine(_horse)).data, 'Vita: 7 / 12');
        expect(
          tester.getTopLeft(_xpLine(_horse)).dy,
          lessThan(tester.getTopLeft(_lifeLine(_horse)).dy),
        );
      },
    );

    testWidgets(
      'tapping a row with the experience line still toggles the companion (D-03)',
      (tester) async {
        final character = await pump(
          tester,
          character: _character(equipped: null, owned: [trainedHorse()]),
        );

        await tapCard(tester, _xpLine(_horse));

        verify(() => companionCubit.toggle(character, _horse)).called(1);
      },
    );
  });

  group('companion life, rest and defeat (FE Phase 22)', () {
    Map<String, dynamic> restingWorg({bool defeated = false}) => ownedPetJson(
      pet: petJson(id: 'pet-worg', name: 'Worg', maxLifePoints: 100),
      currentLifePoints: 20,
      defeated: defeated ? true : null,
      lifeAsOf: _t0.toIso8601String(),
      fullLifeAt: _t0.add(const Duration(minutes: 80)).toIso8601String(),
    );

    testWidgets('the number rises live with the server clock (D-09, D-24)', (
      tester,
    ) async {
      await pump(
        tester,
        character: _character(equipped: null, owned: [restingWorg()]),
      );

      expect(tester.widget<Text>(_lifeLine('pet-worg')).data, 'Vita: 20 / 100');
      expect(
        tester.widget<Text>(_statusLine('pet-worg')).data,
        companionRestingLine(const Duration(minutes: 80)),
      );

      clock.advance(const Duration(minutes: 20));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.widget<Text>(_lifeLine('pet-worg')).data, 'Vita: 40 / 100');
    });

    testWidgets('at fullLifeAt the defeated parchment re-enables locally '
        '(D-24, D-09)', (tester) async {
      final character = await pump(
        tester,
        character: _character(
          equipped: null,
          owned: [restingWorg(defeated: true)],
        ),
      );

      await tapCard(tester, _ownedPet('pet-worg'));
      verifyNever(() => companionCubit.toggle(any(), any()));

      clock.advance(const Duration(minutes: 81));
      await tester.pump(const Duration(seconds: 1));
      await tapCard(tester, _ownedPet('pet-worg'));

      verify(() => companionCubit.toggle(character, 'pet-worg')).called(1);
      expect(_statusLine('pet-worg'), findsNothing);
    });

    testWidgets('the life line uses the companion\'s own max (D-38, D-09)', (
      tester,
    ) async {
      await pump(
        tester,
        character: _character(
          equipped: null,
          owned: [
            ownedPetJson(
              pet: petJson(maxLifePoints: 100),
              currentLifePoints: 150,
              maxLifePoints: 200,
            ),
          ],
        ),
      );

      expect(tester.widget<Text>(_lifeLine(_horse)).data, 'Vita: 150 / 200');
    });

    testWidgets("the slot shows the equipped companion's life (D-04, D-09)", (
      tester,
    ) async {
      await pump(
        tester,
        character: _character(
          owned: [
            ownedPetJson(
              pet: petJson(maxLifePoints: 12),
              currentLifePoints: 10,
            ),
          ],
        ),
      );

      final slotLife = find.byKey(CompanionContent.slotLifeKey);
      expect(tester.widget<Text>(slotLife).data, 'Vita: 10 / 12');
      expect(
        tester.getTopLeft(_slotBox()).dy,
        lessThan(tester.getTopLeft(slotLife).dy),
      );
    });

    testWidgets('no slot life when the slot is empty (D-04)', (tester) async {
      await pump(tester, character: _character(equipped: null));

      expect(find.byKey(CompanionContent.slotLifeKey), findsNothing);
    });

    testWidgets('the long press on a parchment and on the slot asks for the '
        'details (D-22)', (tester) async {
      final character = await pump(tester);

      await tester.ensureVisible(_ownedPet(_cat));
      await tester.pumpAndSettle();
      await tester.longPress(_ownedPet(_cat));
      await tester.pumpAndSettle();
      await tester.longPress(_slotCard(_horse));
      await tester.pumpAndSettle();

      expect(detailsAsked, [_cat, _horse]);
      verifyNever(() => companionCubit.toggle(any(), any()));

      await tapCard(tester, _ownedPet(_cat));

      verify(() => companionCubit.toggle(character, _cat)).called(1);
    });

    testWidgets('the long press asks for the details during a mission (D-22)', (
      tester,
    ) async {
      await pump(tester, character: _character(missionInProgress: true));

      await tester.ensureVisible(_ownedPet(_cat));
      await tester.pumpAndSettle();
      await tester.longPress(_ownedPet(_cat));
      await tester.pumpAndSettle();

      expect(detailsAsked, [_cat]);
    });

    testWidgets('a named companion reads its name on the slot card (D-20)', (
      tester,
    ) async {
      await pump(
        tester,
        character: _character(
          owned: [ownedPetJson(pet: petJson(), name: 'Lampo', level: 2)],
        ),
      );

      final card = _cardOf(tester, _slotBox());
      expect(card.name, 'Lampo');
      expect(card.level, 2);
    });
  });

  group('mission in progress (Phase 21)', () {
    testWidgets('a mission in progress shows «Missione in corso» and ignores '
        'the toggle (D-12, D-30)', (tester) async {
      final haptics = recordHaptics(tester);
      await pump(tester, character: _character(missionInProgress: true));

      expect(find.byKey(CompanionSection.missionLockedKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(CompanionSection.missionLockedKey)).data,
        'Missione in corso',
      );

      await tapCard(tester, _ownedPet(_cat));

      verifyNever(() => companionCubit.toggle(any(), any()));
      expect(haptics, isEmpty);
    });

    testWidgets('no line without a mission (D-12)', (tester) async {
      await pump(tester);

      expect(find.byKey(CompanionSection.missionLockedKey), findsNothing);
      expect(find.text('Missione in corso'), findsNothing);
    });
  });
}
