import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/popup/spell_info_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/journal_harness.dart';
import '../../../../helpers/mocks.dart';

Map<String, dynamic> _spellJson(String letter) =>
    spellJson(id: 'spell-$letter', name: 'Magia $letter');

/// Diario con due magie: A attiva, B no.
Character _spellsCharacter() => journalCharacter(
  spellbook: spellbookCharacterJson(
    spells: [_spellJson('a'), _spellJson('b')],
    activeSpells: [
      activeSpellJson(spellId: 'spell-a', usages: 1, spell: _spellJson('a')),
    ],
    spellStates: [
      spellStateJson(spellId: 'spell-a'),
      spellStateJson(spellId: 'spell-b', usages: 3, recoveries: const []),
    ],
  ),
);

Finder _row(String letter) => find.byKey(ValueKey('spell-row-spell-$letter'));

Finder _slot(String letter) => find.byKey(ValueKey('spell-slot-spell-$letter'));

void main() {
  late MockCharacterCubit characterCubit;
  late MockSpellsCubit spellsCubit;
  final character = _spellsCharacter();

  setUpAll(() => registerFallbackValue(spellbookCharacter()));

  setUp(() {
    characterCubit = MockCharacterCubit();
    spellsCubit = MockSpellsCubit();
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(character),
    );
    whenListen(
      spellsCubit,
      const Stream<SpellsState>.empty(),
      initialState: const SpellsState(),
    );
    when(
      () => spellsCubit.toggle(any(), any()),
    ).thenReturn(SpellToggleIntent.equip);
  });

  Future<void> pumpJournal(WidgetTester tester) => pumpJournalPage(
    tester,
    characterCubit: characterCubit,
    spellsCubit: spellsCubit,
  );

  Future<void> openSpells(WidgetTester tester) async {
    final header = find.text('Magie imparate');
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
  }

  Future<void> longPressAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.longPress(target);
    await tester.pumpAndSettle();
  }

  SpellInfoSheet sheet(WidgetTester tester) =>
      tester.widget<SpellInfoSheet>(find.byType(SpellInfoSheet));

  testWidgets('the journal shows the extracted spells section', (tester) async {
    await pumpJournal(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Magie imparate'), findsOneWidget);
  });

  testWidgets('long-pressing a row raises the spell sheet on the right', (
    tester,
  ) async {
    await pumpJournal(tester);
    await openSpells(tester);

    await longPressAndSettle(tester, _row('b'));

    expect(find.byType(SpellInfoSheet), findsOneWidget);
    expect(sheet(tester).spell.id, 'spell-b');
    expect(sheet(tester).isActive, isFalse);
    final position = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(SpellInfoSheet),
        matching: find.byType(Positioned),
      ),
    );
    expect(position.top, 0);
    expect(position.right, 0);
  });

  testWidgets('the sheet ribbon toggles the spell', (tester) async {
    await pumpJournal(tester);
    await openSpells(tester);
    await longPressAndSettle(tester, _row('b'));

    await tester.tap(
      find.descendant(
        of: find.descendant(
          of: find.byType(SpellInfoSheet),
          matching: find.byType(BookmarkRibbon),
        ),
        matching: find.byType(RotatedBox),
      ),
    );
    await tester.pump();

    verify(() => spellsCubit.toggle(character, 'spell-b')).called(1);
  });

  testWidgets('a tap outside the sheet closes it', (tester) async {
    await pumpJournal(tester);
    await openSpells(tester);
    await longPressAndSettle(tester, _row('b'));

    await tester.tapAt(const Offset(20, 200));
    await tester.pumpAndSettle();

    expect(find.byType(SpellInfoSheet), findsNothing);
  });

  testWidgets('long-pressing a slot card opens the sheet of that spell', (
    tester,
  ) async {
    await pumpJournal(tester);
    await openSpells(tester);

    await longPressAndSettle(tester, _slot('a'));

    expect(sheet(tester).spell.id, 'spell-a');
    expect(sheet(tester).isActive, isTrue);
    expect(sheet(tester).usages, 1);
  });
}
