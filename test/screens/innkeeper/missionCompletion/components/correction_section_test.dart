import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/correction_section.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';

MissionParticipant _participant({int maxLifePoints = 1000}) =>
    MissionParticipant.tryFromJson(
      missionParticipantJson(maxLifePoints: maxLifePoints),
    )!;

/// Scontro simulato: Aldo da 800 a 700, una mano schiacciata, già un occhio nero.
MissionFightOutcome _outcome({
  int hpBefore = 800,
  List<String> injuriesBefore = const ['blackEye'],
  Map<String, dynamic>? simulated,
  Map<String, dynamic>? corrected,
}) => MissionFightOutcome.tryFromJson(
  missionOutcomeJson(
    hpBefore: hpBefore,
    injuriesBefore: injuriesBefore,
    simulated: simulated ?? missionEffectsJson(),
    corrected: corrected,
  ),
)!;

MissionCorrection _seeded(MissionFightOutcome outcome) =>
    MissionCorrection.fromEffects(_aldo, outcome.effective!);

FilterChip _chip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(
      find.byKey(ValueKey('completion.injury.${injury.name}')),
    );

QuantityStepper _stepper(WidgetTester tester, String label) =>
    tester.widget<QuantityStepper>(find.widgetWithText(QuantityStepper, label));

void main() {
  late List<MissionCorrection> changes;

  setUp(() => changes = []);

  Future<void> pumpSection(
    WidgetTester tester, {
    MissionParticipant? participant,
    MissionFightOutcome? outcome,
    MissionCorrection? correction,
    bool opens = true,
  }) async {
    final served = outcome ?? _outcome();
    final shown = participant ?? _participant();
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: SingleChildScrollView(
            child: CorrectionSection(
              participant: shown,
              outcome: served,
              correction: correction ?? _seeded(served),
              itemNameOf: (itemId) =>
                  itemId == potionItemId ? 'Pozione di cura' : null,
              spellNameOf: (spellId) =>
                  spellId == fireballSpellId ? 'Palla di fuoco' : null,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    // una seconda pump sullo stesso albero ritrova la sezione già aperta
    if (!opens || find.text('Ferite').evaluate().isNotEmpty) return;
    await tester.tap(
      find.byKey(CorrectionSection.headerKeyFor(shown.characterId)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts closed under a title with the name and the life change '
      '(UAT 2026-11-14)', (tester) async {
    await pumpSection(tester, opens: false);

    expect(find.text('Aldo · PV 800 → 700'), findsOneWidget);
    expect(find.text('Ferite'), findsNothing);
    expect(
      find.byKey(CorrectionSection.hpSliderKeyFor(_participant().characterId)),
      findsNothing,
    );
  });

  testWidgets('shows the engine line «PV 800 → 700» once open (D-04)', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('PV 800 → 700'), findsOneWidget);
    expect(find.text('Ferite'), findsOneWidget);
  });

  testWidgets(
    'the slider spans 1..maxLifePoints and starts at the effective HP (D-06, rule 4)',
    (tester) async {
      await pumpSection(tester);

      var slider = tester.widget<Slider>(
        find.byKey(CorrectionSection.hpSliderKeyFor(_aldo)),
      );
      expect((slider.min, slider.max, slider.value), (1, 1000, 700));
      expect(find.text('700 / 1000'), findsOneWidget);

      await pumpSection(
        tester,
        outcome: _outcome(corrected: missionEffectsJson(hpAfter: 650)),
      );

      slider = tester.widget<Slider>(
        find.byKey(CorrectionSection.hpSliderKeyFor(_aldo)),
      );
      expect(slider.value, 650);
      expect(find.text('PV 800 → 700'), findsOneWidget);
    },
  );

  testWidgets('moving the slider reports the new HP (D-06)', (tester) async {
    await pumpSection(tester);

    tester
        .widget<Slider>(find.byKey(CorrectionSection.hpSliderKeyFor(_aldo)))
        .onChanged!(500);

    expect(changes.single.hpAfter, 500);
  });

  testWidgets('no slider when maxLifePoints is 1 (Pitfall 9)', (tester) async {
    await pumpSection(
      tester,
      participant: _participant(maxLifePoints: 1),
      outcome: _outcome(hpBefore: 1, simulated: missionEffectsJson(hpAfter: 1)),
    );

    expect(find.byType(Slider), findsNothing);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets(
    'injuriesBefore are locked, the fight\'s injuries toggle (D-14)',
    (tester) async {
      await pumpSection(tester);

      final before = _chip(tester, InjuryType.blackEye);
      expect((before.selected, before.onSelected), (true, null));
      final added = _chip(tester, InjuryType.crushedRightHand);
      expect(added.selected, isTrue);
      added.onSelected!(false);

      final seeded = _seeded(_outcome());
      expect(changes, [seeded.withInjuryToggled(InjuryType.crushedRightHand)]);
      expect(changes.single.injuries, isEmpty);
    },
  );

  testWidgets(
    'injuries added by an earlier fight are locked in the next one (D-14)',
    (tester) async {
      await pumpSection(
        tester,
        outcome: _outcome(
          injuriesBefore: const ['blackEye', 'crushedRightHand'],
          simulated: missionEffectsJson(injuriesAdded: const []),
        ),
      );

      final fromFightOne = _chip(tester, InjuryType.crushedRightHand);
      expect(fromFightOne.selected, isTrue);
      expect(fromFightOne.onSelected, isNull);
    },
  );

  testWidgets(
    'consumable steppers stop at the served availability (D-06, D-17)',
    (tester) async {
      await pumpSection(
        tester,
        outcome: _outcome(
          simulated: missionEffectsJson(
            consumablesUsed: [missionItemUsageJson()],
          ),
        ),
      );

      final potion = _stepper(tester, 'Pozione di cura');
      expect((potion.value, potion.max), (1, 2));
      potion.onChanged(2);

      expect(changes.single.consumablesUsed, {potionItemId: 2});
    },
  );

  testWidgets('spell steppers stop at the served usages (D-06, D-17)', (
    tester,
  ) async {
    await pumpSection(tester);

    final fireball = _stepper(tester, 'Palla di fuoco');
    expect((fireball.value, fireball.max), (0, 2));
    fireball.onChanged(1);

    expect(changes.single.spellsUsed, {fireballSpellId: 1});
  });
}
