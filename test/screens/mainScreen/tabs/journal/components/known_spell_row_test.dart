import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/known_spell_row.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/spells_harness.dart';

final _spellA = Spell.fromJson(spellJson(id: 'spell-a'));

SpellbookEntry _entry({
  int? usages = 3,
  bool isActive = false,
  bool isPending = false,
}) => SpellbookEntry(
  spell: _spellA,
  usages: usages,
  isActive: isActive,
  isPending: isPending,
  recoveries: const [],
);

class _Gestures {
  int taps = 0;
  int longPresses = 0;
}

Future<_Gestures> _pump(
  WidgetTester tester, {
  SpellbookEntry? entry,
  SpellRecoveryStatus recovery = const SpellRecoveryFull(),
  int? resistTrigger,
  _Gestures? gestures,
}) async {
  final recorded = gestures ?? _Gestures();
  await pumpSpellsHarness(
    tester,
    KnownSpellRow(
      entry: entry ?? _entry(),
      recovery: recovery,
      cardSize: 120,
      onTap: () => recorded.taps++,
      onLongPress: () => recorded.longPresses++,
      resistTrigger: resistTrigger,
    ),
  );
  return recorded;
}

SpellCard _card(WidgetTester tester) =>
    tester.widget<SpellCard>(find.byType(SpellCard));

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

double _rowOffsetX(WidgetTester tester) => tester
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
  testWidgets('an inactive spell shows card, description and compact line', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SpellCard), findsOneWidget);
    expect(_card(tester).usages, isNull);
    expect(_card(tester).isMarked, isFalse);
    expect(find.text('Un dardo che brucia il bersaglio'), findsOneWidget);
    expect(
      find.text('Usi: 3 · Recupero: 2 h · Attacco: Fuoco 12'),
      findsOneWidget,
    );
  });

  testWidgets('an active spell carries the bookmark', (tester) async {
    await _pump(tester, entry: _entry(isActive: true));
    await tester.pumpAndSettle();

    expect(_card(tester).isMarked, isTrue);
  });

  testWidgets('usages below the maximum show the countdown', (tester) async {
    await _pump(
      tester,
      entry: _entry(usages: 1),
      recovery: const SpellRecoveryCountdown(remainingMinutes: 12),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Usi: 1/3 · prossimo tra 12 min · Attacco: Fuoco 12'),
      findsOneWidget,
    );
  });

  testWidgets('a pending spell uses the pending ink', (tester) async {
    await _pump(tester, entry: _entry(isPending: true));
    await tester.pumpAndSettle();

    expect(_cardOpacity(tester), KlimmeckGuideTheme.pendingInkOpacity);
  });

  testWidgets('a settled spell is fully opaque', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(_cardOpacity(tester), 1.0);
  });

  testWidgets('tap and long-press are reported', (tester) async {
    final gestures = await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('spell-row-spell-a')));
    await tester.pump();
    await tester.longPress(find.byKey(const ValueKey('spell-row-spell-a')));
    await tester.pump();

    expect(gestures.taps, 1);
    expect(gestures.longPresses, 1);
  });

  testWidgets('a new resist trigger shakes the row', (tester) async {
    final gestures = await _pump(tester);
    await tester.pumpAndSettle();

    await _pump(tester, resistTrigger: 1, gestures: gestures);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    expect(_rowOffsetX(tester), isNot(0));
    await tester.pumpAndSettle();
    expect(_rowOffsetX(tester), 0);
  });
}
