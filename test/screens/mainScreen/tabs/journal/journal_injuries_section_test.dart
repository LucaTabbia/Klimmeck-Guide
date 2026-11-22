import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/section.dart';

import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
  });

  Future<void> pumpJournal(
    WidgetTester tester, {
    required List<String> injuries,
    List<String>? innkeeperInjuries,
  }) async {
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        journalCharacter(
          spellbook: spellbookCharacterJson(),
          injuries: injuries,
          innkeeperInjuries: innkeeperInjuries,
        ),
      ),
    );
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
    );
  }

  testWidgets('without wounds the Journal has no «Ferite» section and leaves '
      'no gap behind (D-22)', (tester) async {
    await pumpJournal(tester, injuries: const []);

    expect(find.text('Ferite'), findsNothing);
    expect(journalSectionHeader('Ferite'), findsNothing);
    expect(
      tester.getTopLeft(journalSectionHeader('Magie imparate')).dy,
      tester.getBottomLeft(_sectionOf('Monete')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('with wounds «Ferite» is a closed dropdown (D-22)', (
    tester,
  ) async {
    await pumpJournal(
      tester,
      injuries: const ['headConcussion', 'missingLeftEye'],
      innkeeperInjuries: const ['missingLeftEye'],
    );

    final header = journalSectionHeader('Ferite');
    expect(header, findsOneWidget);
    expect(
      find.ancestor(of: header, matching: find.byType(Dropdown)),
      findsOneWidget,
    );
    expect(tester.widget<DropdownHeader>(header).turns, 0);
    expect(
      find.text(InjuryType.headConcussion.label).hitTestable(),
      findsNothing,
    );
    expect(find.text(Journal.beyondCureLine).hitTestable(), findsNothing);
  });

  testWidgets('a tap on the «Ferite» header shows the wound rows (D-22)', (
    tester,
  ) async {
    await pumpJournal(
      tester,
      injuries: const ['headConcussion', 'missingLeftEye'],
      innkeeperInjuries: const ['missingLeftEye'],
    );

    await toggleJournalSection(tester, 'Ferite');

    expect(
      tester.widget<DropdownHeader>(journalSectionHeader('Ferite')).turns,
      0.5,
    );
    expect(
      find.text(InjuryType.headConcussion.label).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.text(InjuryType.missingLeftEye.label).hitTestable(),
      findsOneWidget,
    );
    expect(find.text(Journal.beyondCureLine).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _sectionOf(String sectionName) => find.byWidgetPredicate(
  (widget) => widget is Section && widget.sectionName == sectionName,
);
