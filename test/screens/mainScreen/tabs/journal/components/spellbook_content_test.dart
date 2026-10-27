import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/known_spell_row.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_slot_row.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spellbook_content.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';

import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/spells_harness.dart';

Map<String, dynamic> _spellJson(String letter) =>
    spellJson(id: 'spell-$letter', name: 'Magia $letter');

final _spellA = Spell.fromJson(_spellJson('a'));
final _spellB = Spell.fromJson(_spellJson('b'));

/// Magie [C, A, B], A attiva con un uso su tre, due slot.
Spellbook _threeSpellsOneActive() => Spellbook.of(
  spellbookCharacter(
    spells: [_spellJson('c'), _spellJson('a'), _spellJson('b')],
    activeSpells: [
      activeSpellJson(spellId: 'spell-a', usages: 1, spell: _spellJson('a')),
    ],
  ),
);

class _Gestures {
  final toggles = <String>[];
  final details = <Spell>[];
}

Future<_Gestures> _pump(
  WidgetTester tester,
  Spellbook spellbook, {
  Map<String, SpellRecoveryStatus> recoveries = const {},
  SpellResistSignal? resistSignal,
  _Gestures? gestures,
}) async {
  final recorded = gestures ?? _Gestures();
  await pumpSpellsHarness(
    tester,
    SpellbookContent(
      spellbook: spellbook,
      recoveries: recoveries,
      cardSize: 120,
      onToggle: recorded.toggles.add,
      onShowDetails: recorded.details.add,
      resistSignal: resistSignal,
    ),
  );
  return recorded;
}

Finder _row(String letter) => find.byKey(ValueKey('spell-row-spell-$letter'));

Finder _slot(String letter) => find.byKey(ValueKey('spell-slot-spell-$letter'));

Finder _slotBoxes() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('spell-slot-box-'),
);

SpellCard _rowCard(WidgetTester tester, String letter) => tester.widget(
  find.descendant(of: _row(letter), matching: find.byType(SpellCard)),
);

double _offsetXOf(WidgetTester tester, Finder target) => tester
    .widget<Transform>(
      find.descendant(of: target, matching: find.byType(Transform)).first,
    )
    .transform
    .getTranslation()
    .x;

void main() {
  testWidgets('renders the slot row, then the rows in the backend order', (
    tester,
  ) async {
    await _pump(
      tester,
      _threeSpellsOneActive(),
      recoveries: const {
        'spell-a': SpellRecoveryCountdown(remainingMinutes: 12),
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(SpellSlotRow), findsOneWidget);
    expect(_slotBoxes(), findsNWidgets(2));
    expect(find.byType(KnownSpellRow), findsNWidgets(3));
    final top = {
      for (final letter in ['c', 'a', 'b'])
        letter: tester.getTopLeft(_row(letter)).dy,
    };
    expect(top['c']!, lessThan(top['a']!));
    expect(top['a']!, lessThan(top['b']!));
    expect(
      tester.getTopLeft(find.byType(SpellSlotRow)).dy,
      lessThan(top['c']!),
    );
    expect(_rowCard(tester, 'a').isMarked, isTrue);
    expect(_rowCard(tester, 'c').isMarked, isFalse);
    expect(_rowCard(tester, 'b').isMarked, isFalse);
  });

  testWidgets('a missing recovery falls back to the full status', (
    tester,
  ) async {
    await _pump(
      tester,
      _threeSpellsOneActive(),
      recoveries: const {
        'spell-a': SpellRecoveryCountdown(remainingMinutes: 12),
      },
    );
    await tester.pumpAndSettle();

    final rows = tester
        .widgetList<KnownSpellRow>(find.byType(KnownSpellRow))
        .toList();
    expect(rows.map((row) => row.recovery), const [
      SpellRecoveryFull(),
      SpellRecoveryCountdown(remainingMinutes: 12),
      SpellRecoveryFull(),
    ]);
    expect(
      find.text('Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12'),
      findsOneWidget,
    );
    expect(
      find.text('Usi: 3 · Recupero: 2 h · Danno: Fuoco 12'),
      findsNWidgets(2),
    );
  });

  testWidgets('row and slot taps both toggle with the spell id', (
    tester,
  ) async {
    final gestures = await _pump(tester, _threeSpellsOneActive());
    await tester.pumpAndSettle();

    await tester.tap(_row('c'));
    await tester.pump();
    await tester.tap(_slot('a'));
    await tester.pump();

    expect(gestures.toggles, ['spell-c', 'spell-a']);
    expect(gestures.details, isEmpty);
  });

  testWidgets('row and slot long-presses both show the spell details', (
    tester,
  ) async {
    final gestures = await _pump(tester, _threeSpellsOneActive());
    await tester.pumpAndSettle();

    await tester.ensureVisible(_row('b'));
    await tester.pumpAndSettle();
    await tester.longPress(_row('b'));
    await tester.pump();
    await tester.ensureVisible(_slot('a'));
    await tester.pumpAndSettle();
    await tester.longPress(_slot('a'));
    await tester.pump();

    expect(gestures.details, [_spellB, _spellA]);
    expect(gestures.toggles, isEmpty);
  });

  testWidgets(
    'a resist signal shakes the row and the slot card of that spell',
    (tester) async {
      final gestures = await _pump(tester, _threeSpellsOneActive());
      await tester.pumpAndSettle();

      await _pump(
        tester,
        _threeSpellsOneActive(),
        resistSignal: (spellId: 'spell-a', sequence: 1),
        gestures: gestures,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      expect(_offsetXOf(tester, _row('a')), isNot(0));
      expect(_offsetXOf(tester, _slot('a')), isNot(0));
      expect(_offsetXOf(tester, _row('c')), 0);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('slots without known spells show the empty-list line', (
    tester,
  ) async {
    await _pump(tester, Spellbook.of(spellbookCharacter(spells: const [])));
    await tester.pumpAndSettle();

    expect(_slotBoxes(), findsNWidgets(2));
    expect(find.text('Non hai ancora imparato nessuna magia'), findsOneWidget);
    expect(find.byType(KnownSpellRow), findsNothing);
  });

  testWidgets('zero slots show the neutral line and the known rows', (
    tester,
  ) async {
    await _pump(
      tester,
      Spellbook.of(
        spellbookCharacter(maxActiveSpells: 0, spells: [_spellJson('a')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(_slotBoxes(), findsNothing);
    expect(
      find.text('Nessuno slot per le magie: cresci di rango'),
      findsOneWidget,
    );
    expect(find.byType(KnownSpellRow), findsOneWidget);
    expect(find.text('Non hai ancora imparato nessuna magia'), findsNothing);
  });
}
