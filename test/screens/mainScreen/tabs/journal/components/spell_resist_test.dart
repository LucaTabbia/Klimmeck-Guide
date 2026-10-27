import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spell_resist.dart';

import '../../../../../helpers/spells_harness.dart';

const _childKey = ValueKey('resisting-child');

Future<void> _pump(WidgetTester tester, int? trigger) => pumpSpellsHarness(
  tester,
  SpellResist(
    trigger: trigger,
    child: const SizedBox(key: _childKey, width: 50, height: 50),
  ),
);

double _offsetX(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .ancestor(of: find.byKey(_childKey), matching: find.byType(Transform))
          .first,
    )
    .transform
    .getTranslation()
    .x;

Future<void> _pumpToMidShake(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 75));
}

void main() {
  testWidgets('a null trigger leaves the child in place', (tester) async {
    await _pump(tester, null);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), 0);
  });

  testWidgets('a new trigger shakes the child once', (tester) async {
    await _pump(tester, null);
    await _pump(tester, 1);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), isNot(0));

    await tester.pumpAndSettle();
    expect(_offsetX(tester), 0);
  });

  testWidgets('the same trigger does not shake again', (tester) async {
    await _pump(tester, null);
    await _pump(tester, 1);
    await tester.pumpAndSettle();

    await _pump(tester, 1);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), 0);
  });

  testWidgets('a different trigger shakes again', (tester) async {
    await _pump(tester, null);
    await _pump(tester, 1);
    await tester.pumpAndSettle();

    await _pump(tester, 2);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), isNot(0));
    await tester.pumpAndSettle();
  });

  testWidgets('a trigger back to null does not shake', (tester) async {
    await _pump(tester, 1);
    await tester.pumpAndSettle();

    await _pump(tester, null);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), 0);
  });

  testWidgets('the initial trigger does not shake', (tester) async {
    await _pump(tester, 5);
    await _pumpToMidShake(tester);

    expect(_offsetX(tester), 0);
  });

  group('resistTriggerFor', () {
    test('returns the sequence for the signalled spell', () {
      expect(resistTriggerFor((spellId: 'spell-a', sequence: 3), 'spell-a'), 3);
    });

    test('returns null for another spell or no signal', () {
      expect(
        resistTriggerFor((spellId: 'spell-a', sequence: 3), 'spell-b'),
        isNull,
      );
      expect(resistTriggerFor(null, 'spell-a'), isNull);
    });
  });
}
