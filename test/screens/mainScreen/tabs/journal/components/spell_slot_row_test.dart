import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_slot_row.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/spells_harness.dart';

final _spellA = Spell.fromJson(spellJson(id: 'spell-a', name: 'Dardo A'));

List<SpellSlot> _slots({bool isPending = false}) => [
  SpellSlot.filled(spell: _spellA, usages: 2, isPending: isPending),
  const SpellSlot.empty(),
  const SpellSlot.empty(),
];

class _Gestures {
  final taps = <String>[];
  final longPresses = <Spell>[];
}

Future<_Gestures> _pump(
  WidgetTester tester, {
  List<SpellSlot>? slots,
  SpellResistSignal? resistSignal,
  _Gestures? gestures,
}) async {
  final recorded = gestures ?? _Gestures();
  await pumpSpellsHarness(
    tester,
    SpellSlotRow(
      slots: slots ?? _slots(),
      cardSize: 120,
      onTap: recorded.taps.add,
      onLongPress: recorded.longPresses.add,
      resistSignal: resistSignal,
    ),
  );
  return recorded;
}

Finder _slotBoxes() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('spell-slot-box-'),
);

double _cardOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byType(SpellCard),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    )
    .opacity;

double _cardOffsetX(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .ancestor(
            of: find.byType(SpellCard),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getTranslation()
    .x;

void main() {
  testWidgets('renders exactly one box per slot, filled in order', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(_slotBoxes(), findsNWidgets(3));
    for (var index = 0; index < 3; index++) {
      expect(find.byKey(ValueKey('spell-slot-box-$index')), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spell-slot-box-0')),
        matching: find.byType(SpellCard),
      ),
      findsOneWidget,
    );
    final card = tester.widget<SpellCard>(find.byType(SpellCard));
    expect(card.usages, 2);
    expect(card.isMarked, isNull);
  });

  testWidgets('zero slots show the neutral line instead of the row', (
    tester,
  ) async {
    await _pump(tester, slots: const []);
    await tester.pumpAndSettle();

    expect(_slotBoxes(), findsNothing);
    expect(
      find.text('Nessuno slot per le magie: cresci di rango'),
      findsOneWidget,
    );
  });

  testWidgets('a pending slot card uses the pending ink', (tester) async {
    await _pump(tester, slots: _slots(isPending: true));
    await tester.pumpAndSettle();

    expect(_cardOpacity(tester), KlimmeckGuideTheme.pendingInkOpacity);
  });

  testWidgets('a settled slot card is fully opaque', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(_cardOpacity(tester), 1.0);
  });

  testWidgets('tap and long-press on a filled slot are reported', (
    tester,
  ) async {
    final gestures = await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('spell-slot-spell-a')));
    await tester.pump();
    await tester.longPress(find.byKey(const ValueKey('spell-slot-spell-a')));
    await tester.pump();

    expect(gestures.taps, ['spell-a']);
    expect(gestures.longPresses, [_spellA]);
  });

  testWidgets('a tap on an empty box reports nothing', (tester) async {
    final gestures = await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('spell-slot-box-1')));
    await tester.pump();

    expect(gestures.taps, isEmpty);
    expect(gestures.longPresses, isEmpty);
  });

  testWidgets('a resist signal shakes the slot card of that spell', (
    tester,
  ) async {
    final gestures = await _pump(tester);
    await tester.pumpAndSettle();

    await _pump(
      tester,
      resistSignal: (spellId: 'spell-a', sequence: 1),
      gestures: gestures,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    expect(_cardOffsetX(tester), isNot(0));
    await tester.pumpAndSettle();
    expect(_cardOffsetX(tester), 0);
  });
}
