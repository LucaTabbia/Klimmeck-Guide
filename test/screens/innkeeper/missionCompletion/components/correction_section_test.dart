import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/correction_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/life_slider.dart';

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
  Map<String, dynamic>? companion,
  List<String>? innkeeperInjuriesBefore,
}) => MissionFightOutcome.tryFromJson(
  missionOutcomeJson(
    hpBefore: hpBefore,
    injuriesBefore: injuriesBefore,
    simulated: simulated ?? missionEffectsJson(),
    corrected: corrected,
    companion: companion,
    innkeeperInjuriesBefore: innkeeperInjuriesBefore,
  ),
)!;

/// Aldo combatte con Fenrir (300 PV): il motore lo porta da 300 a [lifeAfter].
MissionFightOutcome _outcomeWithCompanion({int? lifeAfter = 120}) => _outcome(
  simulated: missionEffectsJson(companionLifeAfter: lifeAfter),
  companion: missionCompanionJson(),
);

Slider _companionSlider(WidgetTester tester) => tester.widget<Slider>(
  find.byKey(CorrectionSection.companionSliderKeyFor(_aldo)),
);

MissionCorrection _seeded(MissionFightOutcome outcome) =>
    MissionCorrection.fromEffects(_aldo, outcome.effective!);

FilterChip _keptChip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(find.byKey(InjuryChips.keptKeyOf(injury)));

FilterChip _addedChip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(find.byKey(InjuryChips.addedKeyOf(injury)));

String? _labelOf(FilterChip chip) => (chip.label as Text).data;

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
    bool isWoundRemovalEnabled = false,
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
              isWoundRemovalEnabled: isWoundRemovalEnabled,
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

  group('wounds (Phase 24)', () {
    testWidgets('removing a carried wound changes the correction (D-13)', (
      tester,
    ) async {
      await pumpSection(tester, isWoundRemovalEnabled: true);

      final carried = _keptChip(tester, InjuryType.blackEye);
      expect(carried.selected, isTrue);
      carried.onSelected!(false);

      expect(changes.single.injuriesRemoved, [InjuryType.blackEye]);
      expect(changes.single.injuries, [InjuryType.crushedRightHand]);
    });

    testWidgets(
      'removing and adding the same wound keeps it in both lists (D-16)',
      (tester) async {
        final outcome = _outcome();
        await pumpSection(tester, isWoundRemovalEnabled: true);
        _keptChip(tester, InjuryType.blackEye).onSelected!(false);
        await pumpSection(
          tester,
          outcome: outcome,
          correction: changes.last,
          isWoundRemovalEnabled: true,
        );

        final addable = _addedChip(tester, InjuryType.blackEye);
        expect(addable.selected, isFalse);
        addable.onSelected!(true);
        await pumpSection(
          tester,
          outcome: outcome,
          correction: changes.last,
          isWoundRemovalEnabled: true,
        );

        expect(changes.last.injuriesRemoved, [InjuryType.blackEye]);
        expect(changes.last.injuries, [
          InjuryType.crushedRightHand,
          InjuryType.blackEye,
        ]);
        expect(_keptChip(tester, InjuryType.blackEye).selected, isFalse);
        expect(_addedChip(tester, InjuryType.blackEye).selected, isTrue);
      },
    );

    testWidgets('un-removing drops the re-added wound (D-16)', (tester) async {
      final outcome = _outcome();
      final removedAndAdded = _seeded(outcome)
          .withInjuryRemovalToggled(InjuryType.blackEye)
          .withInjuryToggled(InjuryType.blackEye);
      await pumpSection(
        tester,
        outcome: outcome,
        correction: removedAndAdded,
        isWoundRemovalEnabled: true,
      );

      _keptChip(tester, InjuryType.blackEye).onSelected!(true);

      expect(changes.single.injuriesRemoved, isEmpty);
      expect(changes.single.injuries, [InjuryType.crushedRightHand]);
    });

    testWidgets('a wound the fight adds still toggles (D-06)', (tester) async {
      await pumpSection(tester, isWoundRemovalEnabled: true);

      final added = _addedChip(tester, InjuryType.crushedRightHand);
      expect(added.selected, isTrue);
      added.onSelected!(false);

      final seeded = _seeded(_outcome());
      expect(changes, [seeded.withInjuryToggled(InjuryType.crushedRightHand)]);
      expect(changes.single.injuries, isEmpty);
    });

    testWidgets(
      'a wound added by an earlier fight is carried in the next one and '
      'cannot be added twice (D-16)',
      (tester) async {
        await pumpSection(
          tester,
          outcome: _outcome(
            injuriesBefore: const ['blackEye', 'crushedRightHand'],
            simulated: missionEffectsJson(injuriesAdded: const []),
          ),
          isWoundRemovalEnabled: true,
        );

        expect(_keptChip(tester, InjuryType.crushedRightHand).selected, isTrue);
        final addable = _addedChip(tester, InjuryType.crushedRightHand);
        expect((addable.selected, addable.onSelected), (false, null));
      },
    );

    testWidgets(
      'the innkeeper wounds carried before the fight are marked from the '
      'served outcome (D-13)',
      (tester) async {
        await pumpSection(
          tester,
          outcome: _outcome(
            injuriesBefore: const ['blackEye', 'deepCut'],
            innkeeperInjuriesBefore: const ['deepCut'],
          ),
          isWoundRemovalEnabled: true,
        );

        expect(
          _labelOf(_keptChip(tester, InjuryType.deepCut)),
          InjuryChips.innkeeperLabelOf(InjuryType.deepCut),
        );
        expect(
          _labelOf(_keptChip(tester, InjuryType.blackEye)),
          InjuryType.blackEye.label,
        );
      },
    );

    testWidgets(
      'an added wound is marked only when the served effect lists it among '
      'the innkeeper\'s (D-12)',
      (tester) async {
        await pumpSection(
          tester,
          outcome: _outcome(
            corrected: missionEffectsJson(
              injuriesAdded: const ['crushedRightHand', 'deepCut'],
              innkeeperInjuries: const ['deepCut'],
            ),
          ),
          isWoundRemovalEnabled: true,
        );

        expect(
          _labelOf(_addedChip(tester, InjuryType.deepCut)),
          InjuryChips.innkeeperLabelOf(InjuryType.deepCut),
        );
        expect(
          _labelOf(_addedChip(tester, InjuryType.crushedRightHand)),
          InjuryType.crushedRightHand.label,
        );
      },
    );

    testWidgets(
      'with the switch off no carried wound is removable and the note is '
      'absent (pre-gate)',
      (tester) async {
        await pumpSection(tester);

        final carried = _keptChip(tester, InjuryType.blackEye);
        expect((carried.selected, carried.onSelected), (true, null));
        expect(find.byKey(InjuryChips.innkeeperNoteKey), findsNothing);
        final addable = _addedChip(tester, InjuryType.blackEye);
        expect(addable.onSelected, isNull);
      },
    );

    testWidgets('with the switch on the note is drawn (D-12)', (tester) async {
      await pumpSection(tester, isWoundRemovalEnabled: true);

      expect(find.byKey(InjuryChips.innkeeperNoteKey), findsOneWidget);
    });
  });

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

  testWidgets(
    'the character slider keeps its bounds and text (Phase 21 D-06)',
    (tester) async {
      await pumpSection(tester);

      final characterSlider = find.byKey(
        CorrectionSection.hpSliderKeyFor(_aldo),
      );
      expect(
        find.ancestor(of: characterSlider, matching: find.byType(LifeSlider)),
        findsOneWidget,
      );
      final slider = tester.widget<Slider>(characterSlider);
      expect((slider.min, slider.max, slider.divisions), (1, 1000, 999));
      expect(find.text('700 / 1000'), findsOneWidget);
    },
  );

  group('companion life (D-17)', () {
    testWidgets(
      'a participant with a companion shows «Compagno: Fenrir» and its slider (D-17)',
      (tester) async {
        await pumpSection(tester, outcome: _outcomeWithCompanion());

        expect(find.text('Compagno: Fenrir'), findsOneWidget);
        final slider = _companionSlider(tester);
        expect((slider.min, slider.max, slider.value), (1, 300, 120));
        expect(find.text('120 / 300'), findsOneWidget);
        expect(find.byType(LifeSlider), findsNWidgets(2));
        expect(
          find.byKey(CorrectionSection.companionDefeatedKeyFor(_aldo)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'without a served companion life the slider starts at lifeBefore (D-17)',
      (tester) async {
        await pumpSection(
          tester,
          outcome: _outcomeWithCompanion(lifeAfter: null),
        );

        expect(_companionSlider(tester).value, 300);
        expect(find.text('300 / 300'), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(CorrectionSection.companionLifeBeforeKeyFor(_aldo)),
              )
              .data,
          'Vita prima dello scontro',
        );
      },
    );

    testWidgets(
      'a served or corrected companion life is not labelled as the life '
      'before (D-17)',
      (tester) async {
        final outcome = _outcomeWithCompanion(lifeAfter: null);
        await pumpSection(tester, outcome: _outcomeWithCompanion());
        expect(
          find.byKey(CorrectionSection.companionLifeBeforeKeyFor(_aldo)),
          findsNothing,
        );

        await pumpSection(
          tester,
          outcome: outcome,
          correction: _seeded(outcome).withCompanionLife(80),
        );
        expect(
          find.byKey(CorrectionSection.companionLifeBeforeKeyFor(_aldo)),
          findsNothing,
        );
      },
    );

    testWidgets('moving the companion slider sends withCompanionLife (D-17)', (
      tester,
    ) async {
      final outcome = _outcomeWithCompanion();
      await pumpSection(tester, outcome: outcome);

      _companionSlider(tester).onChanged!(80);

      expect(changes, [_seeded(outcome).withCompanionLife(80)]);
      expect(changes.single.companionLifeAfter, 80);
      expect(changes.single.hpAfter, 700);
    });

    testWidgets('at the floor the companion reads «Sconfitto» (D-17)', (
      tester,
    ) async {
      await pumpSection(tester, outcome: _outcomeWithCompanion(lifeAfter: 1));

      expect(
        find.byKey(CorrectionSection.companionDefeatedKeyFor(_aldo)),
        findsOneWidget,
      );
      expect(find.text('Sconfitto'), findsOneWidget);
      expect(find.text('1 / 300'), findsOneWidget);
    });

    testWidgets('without a companion the section is today\'s (D-33)', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.textContaining('Compagno'), findsNothing);
      expect(
        find.byKey(CorrectionSection.companionSliderKeyFor(_aldo)),
        findsNothing,
      );
      expect(find.text('Sconfitto'), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
