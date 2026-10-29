import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_override_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';

ParticipantDraft _draftOf(Map<String, dynamic> json) =>
    ParticipantDraft.from(Character.fromJson(json), fallbackName: 'Aldo');

final ParticipantDraft _aldoDraft = _draftOf(participantCharacterJson());

ParticipantDraft _bareDraft({
  int maxLifePoints = 25,
  int currentLifePoints = 18,
  List<ConsumableLine> consumables = const [],
  List<SpellLine> spells = const [],
}) => ParticipantDraft(
  characterId: _aldo,
  name: 'Aldo',
  currentLifePoints: currentLifePoints,
  maxLifePoints: maxLifePoints,
  hpAfter: currentLifePoints,
  existingInjuries: const [],
  addedInjuries: const [],
  consumables: consumables,
  spells: spells,
);

Finder _stepperButton(Key stepperKey, String tooltip) => find.descendant(
  of: find.byKey(stepperKey),
  matching: find.byTooltip(tooltip),
);

IconButton _iconButton(WidgetTester tester, Finder finder) =>
    tester.widget<IconButton>(
      find.ancestor(of: finder, matching: find.byType(IconButton)).first,
    );

void main() {
  final hpChanges = <int>[];
  final injuryToggles = <InjuryType>[];
  final consumableChanges = <(String, int)>[];
  final spellChanges = <(String, int)>[];

  setUp(() {
    hpChanges.clear();
    injuryToggles.clear();
    consumableChanges.clear();
    spellChanges.clear();
  });

  Future<void> pumpSection(WidgetTester tester, ParticipantDraft draft) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: SingleChildScrollView(
            child: ParticipantOverrideSection(
              draft: draft,
              onHpChanged: hpChanges.add,
              onInjuryToggled: injuryToggles.add,
              onConsumableChanged: (itemId, quantity) =>
                  consumableChanges.add((itemId, quantity)),
              onSpellChanged: (spellId, usages) =>
                  spellChanges.add((spellId, usages)),
            ),
          ),
        ),
      ),
    );
  }

  const consumableKey = ValueKey('completion.consumable.$_aldo.$potionItemId');
  const spellKey = ValueKey('completion.spell.$_aldo.$fireballSpellId');

  group('HP', () {
    testWidgets('a slider 1..max at the current value with the number', (
      tester,
    ) async {
      await pumpSection(tester, _aldoDraft);

      final slider = tester.widget<Slider>(
        find.byKey(ParticipantOverrideSection.hpSliderKey(_aldo)),
      );
      expect(slider.min, 1);
      expect(slider.max, 25);
      expect(slider.value, 18);
      expect(find.text('18 / 25'), findsOneWidget);
      expect(find.text('Aldo'), findsOneWidget);
    });

    testWidgets('dragging the slider reports an int in range', (tester) async {
      await pumpSection(tester, _aldoDraft);

      await tester.drag(
        find.byKey(ParticipantOverrideSection.hpSliderKey(_aldo)),
        const Offset(-200, 0),
      );

      expect(hpChanges, isNotEmpty);
      for (final hp in hpChanges) {
        expect(hp, inInclusiveRange(1, 25));
      }
    });

    testWidgets('max 1 shows only the text', (tester) async {
      await pumpSection(
        tester,
        _bareDraft(maxLifePoints: 1, currentLifePoints: 1),
      );

      expect(find.byType(Slider), findsNothing);
      expect(find.text('1 / 1'), findsOneWidget);
    });
  });

  group('injuries', () {
    testWidgets('one chip per injury with the Italian label', (tester) async {
      await pumpSection(tester, _aldoDraft);

      expect(InjuryType.values.length, 28);
      expect(find.byType(FilterChip), findsNWidgets(28));
      for (final injury in InjuryType.values) {
        expect(find.text(injury.label), findsOneWidget);
      }
    });

    testWidgets('an existing injury is selected and disabled', (tester) async {
      await pumpSection(tester, _aldoDraft);

      final chip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('completion.injury.blackEye')),
      );
      expect(chip.selected, isTrue);
      expect(chip.onSelected, isNull);
    });

    testWidgets('tapping another chip toggles that injury', (tester) async {
      await pumpSection(tester, _aldoDraft);

      const key = ValueKey('completion.injury.brokenLeftArm');
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));

      expect(injuryToggles, [InjuryType.brokenLeftArm]);
    });

    testWidgets('an added injury is selected and enabled', (tester) async {
      await pumpSection(
        tester,
        _aldoDraft.withInjuryToggled(InjuryType.brokenLeftArm),
      );

      final chip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('completion.injury.brokenLeftArm')),
      );
      expect(chip.selected, isTrue);
      expect(chip.onSelected, isNotNull);
    });
  });

  group('consumables', () {
    testWidgets('a stepper per owned loot with its name and count', (
      tester,
    ) async {
      await pumpSection(tester, _aldoDraft);

      expect(find.byKey(consumableKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(consumableKey),
          matching: find.text('Pozione di cura'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(consumableKey),
          matching: find.text('0 / 3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('«+» reports the next quantity, «−» is disabled at 0', (
      tester,
    ) async {
      await pumpSection(tester, _aldoDraft);

      final increase = _stepperButton(consumableKey, 'Aumenta');
      await tester.ensureVisible(increase);
      await tester.tap(increase);

      expect(consumableChanges, [(potionItemId, 1)]);
      expect(
        _iconButton(
          tester,
          _stepperButton(consumableKey, 'Diminuisci'),
        ).onPressed,
        isNull,
      );
    });

    testWidgets('«+» is disabled at owned', (tester) async {
      await pumpSection(tester, _aldoDraft.withConsumableUsed(potionItemId, 3));

      expect(
        _iconButton(tester, _stepperButton(consumableKey, 'Aumenta')).onPressed,
        isNull,
      );
      expect(
        _iconButton(
          tester,
          _stepperButton(consumableKey, 'Diminuisci'),
        ).onPressed,
        isNotNull,
      );
    });

    testWidgets('an unnamed item falls back to «Oggetto»', (tester) async {
      await pumpSection(
        tester,
        _bareDraft(
          consumables: const [
            ConsumableLine(itemId: 'loot-x', name: null, owned: 1, used: 0),
          ],
        ),
      );

      expect(find.text('Oggetto'), findsOneWidget);
    });

    testWidgets('no consumables shows the note', (tester) async {
      await pumpSection(tester, _bareDraft());

      expect(find.text('Nessun consumabile'), findsOneWidget);
      expect(find.byType(QuantityStepper), findsNothing);
    });
  });

  group('spells', () {
    testWidgets('a stepper per active spell bounded at remaining', (
      tester,
    ) async {
      await pumpSection(tester, _aldoDraft);

      expect(
        find.descendant(
          of: find.byKey(spellKey),
          matching: find.text('Palla di fuoco'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(spellKey), matching: find.text('0 / 2')),
        findsOneWidget,
      );
      final increase = _stepperButton(spellKey, 'Aumenta');
      await tester.ensureVisible(increase);
      await tester.tap(increase);
      expect(spellChanges, [(fireballSpellId, 1)]);
    });

    testWidgets('a spell with no uses left has both buttons disabled', (
      tester,
    ) async {
      await pumpSection(
        tester,
        _bareDraft(
          spells: const [
            SpellLine(spellId: 'spell-x', name: null, remaining: 0, used: 0),
          ],
        ),
      );

      const key = ValueKey('completion.spell.$_aldo.spell-x');
      expect(find.text('Magia sconosciuta'), findsOneWidget);
      expect(
        _iconButton(tester, _stepperButton(key, 'Aumenta')).onPressed,
        isNull,
      );
      expect(
        _iconButton(tester, _stepperButton(key, 'Diminuisci')).onPressed,
        isNull,
      );
    });

    testWidgets('no active spells shows the note', (tester) async {
      await pumpSection(tester, _bareDraft());

      expect(find.text('Nessuna magia attiva'), findsOneWidget);
    });
  });

  testWidgets('stepper buttons have a tap target of at least 44 px', (
    tester,
  ) async {
    await pumpSection(tester, _aldoDraft);

    for (final tooltip in ['Aumenta', 'Diminuisci']) {
      final size = tester.getSize(
        find
            .ancestor(
              of: _stepperButton(consumableKey, tooltip),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });
}
