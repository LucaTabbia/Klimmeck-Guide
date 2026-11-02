import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/sections/companion_section.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

const _horse = 'pet-travel-horse';
const _cat = 'pet-cat';

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

Finder _slot() => find.byKey(const ValueKey('companion_slot'));

Finder _ownedPet(String petId) => find.byKey(ValueKey('owned-pet-$petId'));

Finder _inSlot(Finder matching) =>
    find.descendant(of: _slot(), matching: matching);

Finder _inSheet(Finder matching) =>
    find.descendant(of: find.byType(PaperSheetModal), matching: matching);

void main() {
  late MockCharacterCubit characterCubit;
  late MockCompanionCubit companionCubit;

  setUpAll(() => registerFallbackValue(_character()));

  setUp(() {
    characterCubit = MockCharacterCubit();
    companionCubit = MockCompanionCubit();
    when(
      () => companionCubit.toggle(any(), any()),
    ).thenReturn(CompanionToggleIntent.equip);
    seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      CloudinaryAssets.bottomEmptySheet,
    ]);
  });

  Future<Character> pump(
    WidgetTester tester, {
    Character? character,
    CompanionState companion = const CompanionState(),
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
    return shown;
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(_slot());
    await tester.pumpAndSettle();
  }

  Future<void> tapOwned(WidgetTester tester, String petId) async {
    await tester.tapAt(
      tester.getTopLeft(_ownedPet(petId)) + const Offset(20, 10),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the equipped companion with its speed (D-10)', (
    tester,
  ) async {
    await pump(tester);

    final row = tester.widget<CompanionRow>(_inSlot(find.byType(CompanionRow)));
    expect(row.pet.id, _horse);
    expect(find.text('Velocità ×2'), findsOneWidget);
    expect(find.byType(CoinsDisplay), findsNothing);
  });

  testWidgets('shows «$emptyCompanionSlotLine» when none is equipped (D-10)', (
    tester,
  ) async {
    await pump(tester, character: _character(equipped: null));

    expect(_inSlot(find.text(emptyCompanionSlotLine)), findsOneWidget);
    expect(_inSlot(find.byType(CompanionRow)), findsNothing);
  });

  testWidgets('the section is titled «Compagno», never «Cavalcatura» (D-10)', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Compagno'), findsOneWidget);
    expect(find.textContaining('Cavalcatura'), findsNothing);
  });

  testWidgets(
    'a tap opens the owned companions with the equipped one marked (D-10)',
    (tester) async {
      await pump(tester);
      await openSheet(tester);

      expect(_ownedPet(_horse), findsOneWidget);
      expect(_ownedPet(_cat), findsOneWidget);
      expect(_inSheet(find.text(companionEquippedMark)), findsOneWidget);
      expect(tester.widget<CompanionRow>(_ownedPet(_horse)).isEquipped, isTrue);
      expect(_inSheet(find.byType(CoinsDisplay)), findsNothing);
    },
  );

  testWidgets(
    'tapping another owned companion equips it and closes the sheet (D-10)',
    (tester) async {
      final character = await pump(tester);
      await openSheet(tester);
      await tapOwned(tester, _cat);

      verify(() => companionCubit.toggle(character, _cat)).called(1);
      expect(find.byType(PaperSheetModal), findsNothing);
    },
  );

  testWidgets('tapping the equipped companion unequips it (D-10)', (
    tester,
  ) async {
    when(
      () => companionCubit.toggle(any(), any()),
    ).thenReturn(CompanionToggleIntent.unequip);
    final character = await pump(tester);
    await openSheet(tester);
    await tapOwned(tester, _horse);

    verify(() => companionCubit.toggle(character, _horse)).called(1);
    expect(find.byType(PaperSheetModal), findsNothing);
  });

  testWidgets('the slot shows the pending companion at once (D-10)', (
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

    expect(_inSlot(find.text('Gatto di bottega')), findsOneWidget);
    expect(_inSlot(find.text('Cavallo da viaggio')), findsNothing);
  });

  testWidgets('a pending unequip shows the empty slot at once (D-10)', (
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

    expect(_inSlot(find.text(emptyCompanionSlotLine)), findsOneWidget);
    expect(_inSlot(find.byType(CompanionRow)), findsNothing);
  });

  testWidgets(
    'the owned list reads «$noOwnedCompanionsLine» when empty (D-15)',
    (tester) async {
      await pump(tester, character: _character(equipped: null, owning: false));
      await openSheet(tester);

      expect(_inSheet(find.text(noOwnedCompanionsLine)), findsOneWidget);
      expect(_inSheet(find.byType(CompanionRow)), findsNothing);
    },
  );

  testWidgets('stays interactive during a travel (D-10)', (tester) async {
    final character = await pump(
      tester,
      character: _character(activeTravel: activeTravelJson()),
    );
    expect(character.status?.activeTravel, isNotNull);

    await openSheet(tester);

    expect(_ownedPet(_cat), findsOneWidget);
  });
}
