import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/sections/spells_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/popup/spell_info_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/haptic_recorder.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/spells_harness.dart';

Map<String, dynamic> _spellJson(String letter) =>
    spellJson(id: 'spell-$letter', name: 'Magia $letter');

final _spellA = Spell.fromJson(_spellJson('a'));

/// Due slot, A attiva con un uso su tre (recuperi 10:12 e 10:42), B piena.
Character _character({
  int usagesOfA = 1,
  List<Object?> recoveriesOfA = const [
    '2026-10-27T10:12:00.000Z',
    '2026-10-27T10:42:00.000Z',
  ],
  bool withSpellStates = true,
}) => spellbookCharacter(
  spells: [_spellJson('a'), _spellJson('b')],
  activeSpells: [
    activeSpellJson(
      spellId: 'spell-a',
      usages: usagesOfA,
      spell: _spellJson('a'),
    ),
  ],
  spellStates: withSpellStates
      ? [
          spellStateJson(
            spellId: 'spell-a',
            usages: usagesOfA,
            recoveries: recoveriesOfA,
          ),
          spellStateJson(spellId: 'spell-b', usages: 3, recoveries: const []),
        ]
      : null,
);

Finder _row(String letter) => find.byKey(ValueKey('spell-row-spell-$letter'));

Finder _slot(String letter) => find.byKey(ValueKey('spell-slot-spell-$letter'));

Map<String, dynamic> _defenseSpellJson() =>
    spellJson(id: 'spell-b', name: 'Magia b', useType: 'defense');

Map<String, dynamic> _untypedSpellJson() =>
    spellJson(id: 'spell-c', name: 'Magia c', useType: null);

/// A attacco, B difesa e attiva, C senza tipo d'uso; due slot.
Character _mixedUseTypesCharacter() => spellbookCharacter(
  spells: [_spellJson('a'), _defenseSpellJson(), _untypedSpellJson()],
  activeSpells: [
    activeSpellJson(spellId: 'spell-b', usages: 3, spell: _defenseSpellJson()),
  ],
);

Finder _useTypeFilter() => find.byType(ItemsFilter<UseType>);

Finder _chip(UseType useType) => find.descendant(
  of: _useTypeFilter(),
  matching: find.byWidgetPredicate(
    (widget) => widget is CachedSvg && widget.url == useType.imagePath,
  ),
);

Finder _allChip() =>
    find.descendant(of: _useTypeFilter(), matching: find.text('Tutti'));

const _lineOfB = 'Usi: 3 · Recupero: 2 h · Attacco: Fuoco 12';

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  late FakeServerClockService clock;
  late StreamController<CharacterState> characterStates;
  late StreamController<SpellsState> spellsStates;
  late List<({Spell spell, SpellRecoveryCubit recovery})> shownDetails;

  setUpAll(() => registerFallbackValue(spellbookCharacter()));

  void stubToggle(SpellToggleIntent intent) =>
      when(() => spellsCubit.toggle(any(), any())).thenReturn(intent);

  void useCharacter(Character character) {
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(characterStates.close);
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: CharacterLoaded(character),
    );
  }

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    clock = FakeServerClockService(spellFixtureNow);
    spellsStates = StreamController<SpellsState>.broadcast();
    addTearDown(spellsStates.close);
    whenListen(
      spellsCubit,
      spellsStates.stream,
      initialState: const SpellsState(),
    );
    useCharacter(_character());
    stubToggle(SpellToggleIntent.equip);
    shownDetails = [];
  });

  Widget withProviders(Widget body) =>
      RepositoryProvider<ServerClockService>.value(
        value: clock,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<SpellsCubit>.value(value: spellsCubit),
          ],
          child: body,
        ),
      );

  Future<void> pumpSection(WidgetTester tester, {bool open = true}) async {
    await pumpSpellsHarness(
      tester,
      SpellsSection(
        cardSize: 120,
        onShowDetails: (spell, recovery) =>
            shownDetails.add((spell: spell, recovery: recovery)),
      ),
      wrap: withProviders,
    );
    await tester.pumpAndSettle();
    if (!open) return;
    await tester.tap(find.text('Magie imparate'));
    await tester.pumpAndSettle();
  }

  Future<void> emitCharacter(WidgetTester tester, Character character) async {
    final state = CharacterLoaded(character);
    when(() => characterCubit.state).thenReturn(state);
    characterStates.add(state);
    await tester.pump();
  }

  Future<void> emitSpells(WidgetTester tester, SpellsState state) async {
    when(() => spellsCubit.state).thenReturn(state);
    spellsStates.add(state);
    await tester.pump();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> longPress(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.longPress(target);
    await tester.pump();
  }

  group('visibility and content', () {
    testWidgets('no known spells and no slots: no section at all', (
      tester,
    ) async {
      useCharacter(spellbookCharacter(maxActiveSpells: 0, spells: const []));
      await pumpSection(tester, open: false);

      expect(find.text('Magie imparate'), findsNothing);
    });

    testWidgets('rows show usages, countdown and damage; slots hold A', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(
        find.text('Usi: 1/3 · prossimo tra 12 min · Attacco: Fuoco 12'),
        findsOneWidget,
      );
      expect(find.text(_lineOfB), findsOneWidget);
      expect(find.byKey(const ValueKey('spell-slot-box-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('spell-slot-box-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('spell-slot-box-2')), findsNothing);
      final slotCard = tester.widget<SpellCard>(
        find.descendant(
          of: find.byKey(const ValueKey('spell-slot-box-0')),
          matching: find.byType(SpellCard),
        ),
      );
      expect(slotCard.spell.id, 'spell-a');
      expect(slotCard.usages, 1);
    });

    testWidgets('a pre-9.1 payload falls back to «in recupero»', (
      tester,
    ) async {
      useCharacter(_character(withSpellStates: false));
      await pumpSection(tester);

      expect(
        find.text('Usi: 1/3 · in recupero · Attacco: Fuoco 12'),
        findsOneWidget,
      );
    });
  });

  group('taps and haptics', () {
    testWidgets('an accepted row tap toggles with a light impact', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      await pumpSection(tester);

      await tapAndSettle(tester, _row('b'));

      verify(() => spellsCubit.toggle(_character(), 'spell-b')).called(1);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('a blocked tap gives a selection click', (tester) async {
      stubToggle(SpellToggleIntent.blockedSlotsFull);
      final haptics = recordHaptics(tester);
      await pumpSection(tester);

      await tapAndSettle(tester, _row('b'));

      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('an ignored tap gives no haptic', (tester) async {
      stubToggle(SpellToggleIntent.ignoredPending);
      final haptics = recordHaptics(tester);
      await pumpSection(tester);

      await tapAndSettle(tester, _row('b'));

      verify(() => spellsCubit.toggle(any(), 'spell-b')).called(1);
      expect(haptics, isEmpty);
    });

    testWidgets('tapping the slot card toggles its spell', (tester) async {
      await pumpSection(tester);

      await tapAndSettle(tester, _slot('a'));

      verify(() => spellsCubit.toggle(any(), 'spell-a')).called(1);
    });
  });

  group('long-press', () {
    testWidgets('row and slot card show the details with the countdown', (
      tester,
    ) async {
      await pumpSection(tester);

      await longPress(tester, _row('a'));
      await longPress(tester, _slot('a'));

      expect(shownDetails.map((shown) => shown.spell), [_spellA, _spellA]);
      expect(shownDetails.first.recovery.isClosed, isFalse);
      verifyNever(() => spellsCubit.toggle(any(), any()));
    });
  });

  group('optimistic overlay', () {
    testWidgets('a pending equip dims the row and fills the next slot', (
      tester,
    ) async {
      await pumpSection(tester);

      await emitSpells(
        tester,
        const SpellsState(pending: {'spell-b': SpellOperation.equip}),
      );
      await tester.pumpAndSettle();

      final rowInk = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.descendant(
                of: _row('b'),
                matching: find.byType(SpellCard),
              ),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(rowInk.opacity, KlimmeckGuideTheme.pendingInkOpacity);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('spell-slot-box-1')),
          matching: _slot('b'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a blocked outcome shakes the row', (tester) async {
      await pumpSection(tester);

      await emitSpells(
        tester,
        const SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: 'spell-b',
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.blockedSlotsFull,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      final shake = tester
          .widget<Transform>(
            find
                .descendant(of: _row('b'), matching: find.byType(Transform))
                .first,
          )
          .transform
          .getTranslation()
          .x;
      expect(shake, isNot(0));
      await tester.pumpAndSettle();
    });
    testWidgets('a settle by timeout does not shake the row (WR-01)', (
      tester,
    ) async {
      await pumpSection(tester);

      await emitSpells(
        tester,
        const SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: 'spell-b',
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.settledByTimeout,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      final shake = tester
          .widget<Transform>(
            find
                .descendant(of: _row('b'), matching: find.byType(Transform))
                .first,
          )
          .transform
          .getTranslation()
          .x;
      expect(shake, 0);
      await tester.pumpAndSettle();
    });
  });

  group('live countdown', () {
    testWidgets('a new character re-follows the recovery', (tester) async {
      await pumpSection(tester);

      await emitCharacter(
        tester,
        _character(
          usagesOfA: 2,
          recoveriesOfA: const ['2026-10-27T10:42:00.000Z'],
        ),
      );
      await tester.pump();

      expect(
        find.text('Usi: 2/3 · prossimo tra 42 min · Attacco: Fuoco 12'),
        findsOneWidget,
      );
    });

    testWidgets('the ticker follows the server clock', (tester) async {
      await pumpSection(tester);

      clock.advance(const Duration(minutes: 1, seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Usi: 1/3 · prossimo tra 11 min · Attacco: Fuoco 12'),
        findsOneWidget,
      );
    });

    testWidgets('unmounting the section stops the ticker', (tester) async {
      await pumpSection(tester);
      await longPress(tester, _row('a'));
      final recovery = shownDetails.single.recovery;

      await tester.pumpWidget(const SizedBox());

      expect(recovery.isClosed, isTrue);
    });
  });

  group('use-type filter', () {
    testWidgets('a chip filters the known rows, «Tutti» restores them', (
      tester,
    ) async {
      useCharacter(_mixedUseTypesCharacter());
      await pumpSection(tester);

      await tapAndSettle(tester, _chip(UseType.attack));
      await tester.pumpAndSettle();

      expect(_row('a'), findsOneWidget);
      expect(_row('b'), findsNothing);
      expect(_row('c'), findsNothing);
      expect(_slot('b'), findsOneWidget);

      await tapAndSettle(tester, _allChip());
      await tester.pumpAndSettle();

      for (final letter in ['a', 'b', 'c']) {
        expect(_row(letter), findsOneWidget);
      }
      verifyNever(() => spellsCubit.toggle(any(), any()));
    });

    testWidgets('a vanished type drops the selection for good', (tester) async {
      useCharacter(_mixedUseTypesCharacter());
      await pumpSection(tester);

      await tapAndSettle(tester, _chip(UseType.defense));
      await tester.pumpAndSettle();
      expect(_row('a'), findsNothing);

      await emitCharacter(
        tester,
        spellbookCharacter(spells: [_spellJson('a'), _untypedSpellJson()]),
      );
      await tester.pumpAndSettle();

      expect(_row('a'), findsOneWidget);
      expect(_row('c'), findsOneWidget);
      final filter = tester.widget<ItemsFilter<UseType>>(_useTypeFilter());
      expect(filter.current, isNull);
      expect(filter.values, [UseType.attack]);

      await emitCharacter(tester, _mixedUseTypesCharacter());
      await tester.pumpAndSettle();

      for (final letter in ['a', 'b', 'c']) {
        expect(_row(letter), findsOneWidget);
      }
      verifyNever(() => spellsCubit.toggle(any(), any()));
    });
  });

  group('SpellDetailsSheet', () {
    testWidgets('binds the live state and toggles from the ribbon', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      await pumpSpellsHarness(
        tester,
        BlocProvider<SpellRecoveryCubit>(
          create: (_) => SpellRecoveryCubit(clock: clock)
            ..follow(SpellRecoveryCubit.inputsOf(Spellbook.of(_character()))),
          child: SpellDetailsSheet(spell: _spellA),
        ),
        wrap: withProviders,
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<SpellInfoSheet>(find.byType(SpellInfoSheet));
      expect(sheet.isActive, isTrue);
      expect(sheet.isPending, isFalse);
      expect(sheet.usages, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(BookmarkRibbon),
          matching: find.byType(RotatedBox),
        ),
      );
      await tester.pump();

      verify(() => spellsCubit.toggle(_character(), 'spell-a')).called(1);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(sheet.recovery, isA<SpellRecoveryCountdown>());
    });
  });
}
