import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

Character _wounded({
  required List<String> injuries,
  List<String>? innkeeperInjuries,
}) => journalCharacter(
  spellbook: spellbookCharacterJson(),
  injuries: injuries,
  innkeeperInjuries: innkeeperInjuries,
);

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
    WidgetTester tester,
    Character character, {
    Stream<CharacterState> updates = const Stream.empty(),
    Map<NewEntryCategory, Set<String>> highlighted = const {},
  }) async {
    whenListen(
      characterCubit,
      updates,
      initialState: CharacterLoaded(character),
    );
    await pumpJournalPage(
      tester,
      characterCubit: characterCubit,
      spellsCubit: spellsCubit,
      newEntriesCubit: quietNewEntriesCubit(
        NewEntriesState(highlighted: highlighted),
      ),
    );
  }

  testWidgets(
    'an innkeeper wound reads Troppo grave per essere curata under its name (D-15)',
    (tester) async {
      await pumpJournal(
        tester,
        _wounded(
          injuries: const ['headConcussion', 'missingLeftEye'],
          innkeeperInjuries: const ['missingLeftEye'],
        ),
      );

      final line = find.byKey(
        Journal.beyondCureKeyOf(InjuryType.missingLeftEye),
      );
      expect(line, findsOneWidget);
      expect(tester.widget<Text>(line).data, 'Troppo grave per essere curata');
      expect(
        tester.getTopLeft(line).dy,
        greaterThan(
          tester.getBottomLeft(find.text(InjuryType.missingLeftEye.label)).dy -
              1,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an ordinary wound reads no such line (D-15)', (tester) async {
    await pumpJournal(
      tester,
      _wounded(
        injuries: const ['headConcussion', 'missingLeftEye'],
        innkeeperInjuries: const ['missingLeftEye'],
      ),
    );

    expect(
      find.byKey(Journal.beyondCureKeyOf(InjuryType.headConcussion)),
      findsNothing,
    );
    expect(find.text(Journal.beyondCureLine), findsOneWidget);
  });

  testWidgets(
    'the line appears when only the origin of a wound changes (Pitfall 4)',
    (tester) async {
      final updates = StreamController<CharacterState>();
      addTearDown(updates.close);
      await pumpJournal(
        tester,
        _wounded(injuries: const ['missingLeftEye']),
        updates: updates.stream,
      );
      expect(find.text(Journal.beyondCureLine), findsNothing);

      updates.add(
        CharacterLoaded(
          _wounded(
            injuries: const ['missingLeftEye'],
            innkeeperInjuries: const ['missingLeftEye'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Journal.beyondCureKeyOf(InjuryType.missingLeftEye)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the wound row does not overflow on a narrow page with the line and the new-entry sigil',
    (tester) async {
      await pumpJournal(
        tester,
        _wounded(
          injuries: const ['traumaticBrainInjury'],
          innkeeperInjuries: const ['traumaticBrainInjury'],
        ),
        highlighted: {
          NewEntryCategory.injuries: {'traumaticBrainInjury'},
        },
      );
      tester.view.physicalSize = const Size(1440, 1080);
      await tester.pumpAndSettle();

      expect(
        find.byKey(Journal.beyondCureKeyOf(InjuryType.traumaticBrainInjury)),
        findsOneWidget,
      );
      expect(
        find.byKey(Journal.newInjuryKeyOf(InjuryType.traumaticBrainInjury)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
