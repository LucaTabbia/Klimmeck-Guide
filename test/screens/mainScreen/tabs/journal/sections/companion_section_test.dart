import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/owned_companion_row.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/sections/companion_section.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:mocktail/mocktail.dart';

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

Character _character({
  String? equipped = _horse,
  bool owning = true,
  Map<String, dynamic>? activeTravel,
}) => Character.fromJson({
  ...travellingCharacterJson(activeTravel: activeTravel),
  'assets': {
    'pet': switch (equipped) {
      _horse => petJson(),
      _cat => catPetJson(),
      _ => null,
    },
    'ownedPets': owning ? [petJson(), catPetJson()] : const [],
  },
});

Finder _slotBox() => find.byKey(const ValueKey('companion-slot-box'));

Finder _slotCard(String petId) => find.byKey(ValueKey('companion-slot-$petId'));

Finder _ownedPet(String petId) => find.byKey(ValueKey('owned-pet-$petId'));

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

  setUpAll(() => registerFallbackValue(_character()));

  void stubToggle(CompanionToggleIntent intent) =>
      when(() => companionCubit.toggle(any(), any())).thenReturn(intent);

  setUp(() {
    characterCubit = MockCharacterCubit();
    companionCubit = MockCompanionCubit();
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<CompanionCubit>.value(value: companionCubit),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: CompanionSection(size: 60)),
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
}
