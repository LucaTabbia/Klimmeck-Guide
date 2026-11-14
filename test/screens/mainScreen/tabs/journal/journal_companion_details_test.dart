import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_name_sheet.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/haptic_recorder.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

const String _worg = 'pet-worg';
const String _horse = 'pet-travel-horse';
const Duration _restLeft = Duration(minutes: 80);

const _attack = <String, dynamic>{
  'base': [
    {'type': 'cut', 'power': 12},
  ],
  'energy': [],
};
const _defense = <String, dynamic>{
  'base': [
    {'type': 'blunt', 'power': 4},
  ],
  'energy': [],
};

Map<String, dynamic> _worgJson({bool defeated = false}) => ownedPetJson(
  pet: petJson(
    id: _worg,
    name: 'Worg',
    speedModifier: null,
    maxXp: 300,
    maxLifePoints: 100,
    attack: _attack,
    defense: _defense,
  ),
  xp: 40,
  currentLifePoints: 20,
  name: 'Zanna',
  defeated: defeated ? true : null,
  lifeAsOf: spellFixtureNow.toIso8601String(),
  fullLifeAt: spellFixtureNow.add(_restLeft).toIso8601String(),
);

Character _character({
  bool defeated = false,
  bool missionInProgress = false,
  bool ownsWorg = true,
}) => journalCharacter(
  spellbook: {
    ...spellbookCharacterJson(),
    'assets': {
      'pet': petJson(),
      'ownedPets': [
        ownedPetJson(pet: petJson()),
        if (ownsWorg) _worgJson(defeated: defeated),
      ],
    },
  },
  missionInProgress: missionInProgress,
);

Finder _ownedPet(String petId) => find.byKey(ValueKey('owned-pet-$petId'));

Finder _ribbon() => find.descendant(
  of: find.descendant(
    of: find.byType(CompanionInfoSheet),
    matching: find.byType(BookmarkRibbon),
  ),
  matching: find.byType(RotatedBox),
);

String? _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late MockCompanionCubit companionCubit;
  late MockCompanionNameCubit companionNameCubit;

  setUpAll(() => registerFallbackValue(_character()));

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    companionCubit = MockCompanionCubit();
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    whenListen(
      companionCubit,
      const Stream<CompanionState>.empty(),
      initialState: const CompanionState(),
    );
    when(
      () => companionCubit.toggle(any(), any()),
    ).thenReturn(CompanionToggleIntent.equip);
    companionNameCubit = MockCompanionNameCubit();
    whenListen(
      companionNameCubit,
      const Stream<CompanionNameState>.empty(),
      initialState: const CompanionNameIdle(),
    );
    when(() => companionNameCubit.reset()).thenReturn(null);
  });

  Future<Character> pumpJournal(
    WidgetTester tester, {
    bool defeated = false,
    bool missionInProgress = false,
    bool isCompanionNamingEnabled = false,
    Stream<CharacterState> updates = const Stream.empty(),
  }) async {
    final character = _character(
      defeated: defeated,
      missionInProgress: missionInProgress,
    );
    whenListen(
      characterCubit,
      updates,
      initialState: CharacterLoaded(character),
    );
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
      companionCubit: companionCubit,
      clock: FakeServerClockService(spellFixtureNow),
      companionNameCubit: companionNameCubit,
      isCompanionNamingEnabled: isCompanionNamingEnabled,
    );
    final header = find.text('Compagno');
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
    return character;
  }

  Future<void> longPressWorg(WidgetTester tester) async {
    await tester.ensureVisible(_ownedPet(_worg));
    await tester.pumpAndSettle();
    await tester.longPress(_ownedPet(_worg));
    await tester.pumpAndSettle();
  }

  CompanionInfoSheet sheet(WidgetTester tester) =>
      tester.widget<CompanionInfoSheet>(find.byType(CompanionInfoSheet));

  testWidgets(
    'long press on a companion parchment opens its details sheet in the '
    'Journal (D-22)',
    (tester) async {
      await pumpJournal(tester);
      expect(find.byType(CompanionInfoSheet), findsNothing);

      await longPressWorg(tester);

      expect(find.byType(CompanionInfoSheet), findsOneWidget);
      expect(sheet(tester).pet.id, _worg);
      expect(_textOf(tester, CompanionInfo.titleKey), 'Zanna');
      expect(sheet(tester).isEquipped, isFalse);
      verifyNever(() => companionCubit.toggle(any(), any()));
    },
  );

  testWidgets(
    'the details show life, rest, attack, defense and experience (D-09, D-22)',
    (tester) async {
      await pumpJournal(tester);

      await longPressWorg(tester);

      expect(_textOf(tester, CompanionInfo.lifeKey), 'Vita: 20 / 100');
      expect(
        _textOf(tester, CompanionInfo.statusKey),
        companionRestingLine(_restLeft),
      );
      expect(_textOf(tester, CompanionInfo.attackKey), 'Attacco: tagliente 12');
      expect(
        _textOf(tester, CompanionInfo.defenseKey),
        'Difesa: contundente 4',
      );
      expect(_textOf(tester, CompanionInfo.xpKey), 'Esperienza: 40 / 300');
    },
  );

  testWidgets('the bookmark of the details toggles the companion (D-22)', (
    tester,
  ) async {
    final character = await pumpJournal(tester);
    await longPressWorg(tester);

    await tester.tap(_ribbon());
    await tester.pump();

    verify(() => companionCubit.toggle(character, _worg)).called(1);
  });

  testWidgets('the bookmark of the details confirms the toggle with a haptic, '
      'as the parchment does (D-22)', (tester) async {
    await pumpJournal(tester);
    await longPressWorg(tester);
    final haptics = recordHaptics(tester);

    await tester.tap(_ribbon());
    await tester.pump();

    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('the equipped companion opens from the slot bookmarked (D-22)', (
    tester,
  ) async {
    await pumpJournal(tester);
    final slotCard = find.byKey(const ValueKey('companion-slot-$_horse'));
    await tester.ensureVisible(slotCard);
    await tester.pumpAndSettle();

    await tester.longPress(slotCard);
    await tester.pumpAndSettle();

    expect(sheet(tester).pet.id, _horse);
    expect(sheet(tester).isEquipped, isTrue);
  });

  testWidgets('the bookmark is off for a defeated companion (D-02, D-22)', (
    tester,
  ) async {
    await pumpJournal(tester, defeated: true);
    await longPressWorg(tester);

    expect(sheet(tester).onToggle, isNull);
    expect(
      _textOf(tester, CompanionInfo.statusKey),
      companionDefeatedLine(_restLeft),
    );

    await tester.tap(_ribbon(), warnIfMissed: false);
    await tester.pump();

    verifyNever(() => companionCubit.toggle(any(), any()));
  });

  testWidgets('the bookmark is off during a mission (D-22, Phase 21 D-12)', (
    tester,
  ) async {
    await pumpJournal(tester, missionInProgress: true);
    await longPressWorg(tester);

    expect(find.byType(CompanionInfoSheet), findsOneWidget);
    expect(sheet(tester).onToggle, isNull);

    await tester.tap(_ribbon(), warnIfMissed: false);
    await tester.pump();

    verifyNever(() => companionCubit.toggle(any(), any()));
  });

  testWidgets(
    'the details offer «Dai un nome» or «Cambia nome» only with the switch '
    'on (D-19, Pitfall 3)',
    (tester) async {
      await pumpJournal(tester);
      await longPressWorg(tester);

      expect(sheet(tester).onRename, isNull);
      expect(find.byKey(CompanionInfo.renameKey), findsNothing);

      await pumpJournal(tester, isCompanionNamingEnabled: true);
      await longPressWorg(tester);

      expect(sheet(tester).onRename, isNotNull);
      expect(_textOf(tester, CompanionInfo.renameKey), 'Cambia nome');
    },
  );

  testWidgets('the rename stays available during a mission (D-31)', (
    tester,
  ) async {
    await pumpJournal(
      tester,
      missionInProgress: true,
      isCompanionNamingEnabled: true,
    );
    await longPressWorg(tester);

    expect(sheet(tester).onToggle, isNull);
    expect(sheet(tester).onRename, isNotNull);
  });

  testWidgets('tapping it opens the name prompt with the current name (D-19)', (
    tester,
  ) async {
    final character = await pumpJournal(tester, isCompanionNamingEnabled: true);
    await longPressWorg(tester);

    await tester.ensureVisible(find.byKey(CompanionInfo.renameKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompanionInfo.renameKey));
    await tester.pumpAndSettle();

    final prompt = tester.widget<CompanionNameSheet>(
      find.byType(CompanionNameSheet),
    );
    expect(prompt.characterId, character.id);
    expect(prompt.petId, _worg);
    expect(prompt.species, 'Worg');
    expect(prompt.initialName, 'Zanna');
    expect(find.text('Come chiamerai il tuo Worg?'), findsOneWidget);
  });

  testWidgets(
    'the details slide away when their companion leaves the owned list '
    '(D-22)',
    (tester) async {
      final updates = StreamController<CharacterState>.broadcast();
      addTearDown(updates.close);
      await pumpJournal(tester, updates: updates.stream);
      await longPressWorg(tester);
      final panel = tester.element(
        find
            .ancestor(
              of: find.byType(CompanionInfoSheet),
              matching: find.byType(Positioned),
            )
            .first,
      );

      updates.add(CharacterLoaded(_character(ownsWorg: false)));
      await tester.pumpAndSettle();

      expect(find.byType(CompanionInfoSheet), findsNothing);
      expect(
        (panel.widget as Positioned).top,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
    },
  );

  testWidgets('a tap outside the companion sheet closes it (D-22)', (
    tester,
  ) async {
    await pumpJournal(tester);
    await longPressWorg(tester);

    await tester.tapAt(const Offset(20, 200));
    await tester.pumpAndSettle();

    expect(find.byType(CompanionInfoSheet), findsNothing);
  });
}
