import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

Finder sigilIn(Finder scope) =>
    find.descendant(of: scope, matching: find.byType(NewEntrySigil));

Finder headerOf(String sectionName) => find.byWidgetPredicate(
  (widget) => widget is DropdownHeader && widget.sectionName == sectionName,
);

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        journalCharacter(
          spellbook: spellbookCharacterJson(
            spellStates: [
              spellStateJson(spellId: 's-old'),
              spellStateJson(spellId: 's-new'),
            ],
          ),
          ownedItems: [ownedHealPotionJson()],
          injuries: const ['headConcussion', 'missingLeftEye'],
        ),
      ),
    );
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
  });

  Future<MockNewEntriesCubit> pumpJournal(
    WidgetTester tester, {
    Map<NewEntryCategory, Set<String>> highlighted = const {},
  }) async {
    final entries = quietNewEntriesCubit(
      NewEntriesState(highlighted: highlighted),
    );
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
      newEntriesCubit: entries,
    );
    return entries;
  }

  testWidgets('entering the Journal visits its categories', (tester) async {
    final entries = await pumpJournal(tester);

    verify(() => entries.visit(NewEntryCategory.journal)).called(1);
  });

  testWidgets('with nothing new the Journal shows no sigil', (tester) async {
    await pumpJournal(tester);

    expect(find.byType(NewEntrySigil), findsNothing);
  });

  testWidgets('a new injury carries the sigil beside its name', (tester) async {
    await pumpJournal(
      tester,
      highlighted: {
        NewEntryCategory.injuries: {'missingLeftEye'},
      },
    );

    expect(
      find.byKey(Journal.newInjuryKeyOf(InjuryType.missingLeftEye)),
      findsOneWidget,
    );
    expect(
      find.byKey(Journal.newInjuryKeyOf(InjuryType.headConcussion)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a new spell marks the closed «Magie imparate» header and its own row',
    (tester) async {
      await pumpJournal(
        tester,
        highlighted: {
          NewEntryCategory.spells: {'s-new'},
        },
      );

      expect(sigilIn(headerOf('Magie imparate')), findsOneWidget);
      expect(sigilIn(headerOf('Oggetti')), findsNothing);
      expect(sigilIn(headerOf('Compagno')), findsNothing);
      expect(sigilIn(headerOf('Armatura')), findsNothing);

      await tester.tap(find.text('Magie imparate'));
      await tester.pumpAndSettle();

      final marked = tester
          .widgetList<NewEntryMarked>(find.byType(NewEntryMarked))
          .where((mark) => mark.isNew)
          .map((mark) => mark.key);
      expect(marked, [const ValueKey('s-new')]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a new item marks the «Oggetti» header and its parchment', (
    tester,
  ) async {
    await pumpJournal(
      tester,
      highlighted: {
        NewEntryCategory.items: {'l-herb'},
      },
    );

    expect(sigilIn(headerOf('Oggetti')), findsOneWidget);

    await tester.ensureVisible(find.text('Oggetti'));
    await tester.tap(find.text('Oggetti'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<NewEntryMarked>(find.byType(NewEntryMarked))
          .where((mark) => mark.isNew),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });
}
