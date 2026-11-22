import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';

import '../../../helpers/test_app.dart';

FilterChip _keptChip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(find.byKey(InjuryChips.keptKeyOf(injury)));

FilterChip _addedChip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(find.byKey(InjuryChips.addedKeyOf(injury)));

String? _labelOf(FilterChip chip) => (chip.label as Text).data;

void main() {
  late List<InjuryType> removalToggles;
  late List<InjuryType> addToggles;

  setUp(() {
    removalToggles = [];
    addToggles = [];
  });

  Future<void> pumpChips(
    WidgetTester tester, {
    required bool isRemovalEnabled,
    List<InjuryType> carried = const [InjuryType.blackEye],
    List<InjuryType> innkeeperCarried = const [],
    List<InjuryType> removed = const [],
    List<InjuryType> added = const [InjuryType.crushedRightHand],
    List<InjuryType> innkeeperAdded = const [],
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: SingleChildScrollView(
            child: InjuryChips(
              carried: carried,
              innkeeperCarried: innkeeperCarried,
              removed: removed,
              added: added,
              innkeeperAdded: innkeeperAdded,
              onRemovalToggled: isRemovalEnabled ? removalToggles.add : null,
              onAddToggled: addToggles.add,
            ),
          ),
        ),
      ),
    );
  }

  group('Ferite presenti', () {
    testWidgets(
      'a carried wound is shown as kept and a tap asks to remove it (D-13)',
      (tester) async {
        await pumpChips(tester, isRemovalEnabled: true);

        expect(find.text(InjuryChips.carriedHeading), findsOneWidget);
        final chip = _keptChip(tester, InjuryType.blackEye);
        expect(chip.selected, isTrue);
        chip.onSelected!(false);

        expect(removalToggles, [InjuryType.blackEye]);
        expect(addToggles, isEmpty);
      },
    );

    testWidgets(
      'a removed wound is shown unselected and a tap keeps it again',
      (tester) async {
        await pumpChips(
          tester,
          isRemovalEnabled: true,
          removed: const [InjuryType.blackEye],
        );

        final chip = _keptChip(tester, InjuryType.blackEye);
        expect(chip.selected, isFalse);
        chip.onSelected!(true);

        expect(removalToggles, [InjuryType.blackEye]);
      },
    );

    testWidgets('a carried wound of the innkeeper carries the mark (D-13)', (
      tester,
    ) async {
      await pumpChips(
        tester,
        isRemovalEnabled: true,
        carried: const [InjuryType.blackEye, InjuryType.deepCut],
        innkeeperCarried: const [InjuryType.deepCut],
      );

      expect(
        _labelOf(_keptChip(tester, InjuryType.deepCut)),
        InjuryChips.innkeeperLabelOf(InjuryType.deepCut),
      );
      expect(
        InjuryChips.innkeeperLabelOf(InjuryType.deepCut),
        '${InjuryType.deepCut.label} (dell\'oste)',
      );
    });

    testWidgets('an ordinary carried wound carries no mark', (tester) async {
      await pumpChips(
        tester,
        isRemovalEnabled: true,
        carried: const [InjuryType.blackEye, InjuryType.deepCut],
        innkeeperCarried: const [InjuryType.deepCut],
      );

      expect(
        _labelOf(_keptChip(tester, InjuryType.blackEye)),
        InjuryType.blackEye.label,
      );
    });

    testWidgets(
      'the group Ferite presenti is absent for a participant without wounds',
      (tester) async {
        await pumpChips(tester, isRemovalEnabled: true, carried: const []);

        expect(find.text(InjuryChips.carriedHeading), findsNothing);
        expect(find.text(InjuryChips.addedHeading), findsOneWidget);
        expect(
          find.byKey(InjuryChips.keptKeyOf(InjuryType.blackEye)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'with removal off the carried wounds are shown and not tappable '
      '(pre-gate)',
      (tester) async {
        await pumpChips(tester, isRemovalEnabled: false);

        final chip = _keptChip(tester, InjuryType.blackEye);
        expect(chip.selected, isTrue);
        expect(chip.onSelected, isNull);
      },
    );
  });

  group('Ferite da aggiungere', () {
    testWidgets('a carried wound not removed cannot be added (D-16)', (
      tester,
    ) async {
      await pumpChips(tester, isRemovalEnabled: true);

      final chip = _addedChip(tester, InjuryType.blackEye);
      expect(chip.selected, isFalse);
      expect(chip.onSelected, isNull);
    });

    testWidgets('a removed wound can be added again (D-16)', (tester) async {
      await pumpChips(
        tester,
        isRemovalEnabled: true,
        removed: const [InjuryType.blackEye],
      );

      final chip = _addedChip(tester, InjuryType.blackEye);
      expect(chip.selected, isFalse);
      chip.onSelected!(true);

      expect(addToggles, [InjuryType.blackEye]);
      expect(removalToggles, isEmpty);
    });

    testWidgets('a wound not carried toggles as before', (tester) async {
      await pumpChips(tester, isRemovalEnabled: true);

      final fromTheFight = _addedChip(tester, InjuryType.crushedRightHand);
      expect(fromTheFight.selected, isTrue);
      fromTheFight.onSelected!(false);
      final absent = _addedChip(tester, InjuryType.brokenLeftArm);
      expect(absent.selected, isFalse);
      absent.onSelected!(true);

      expect(addToggles, [
        InjuryType.crushedRightHand,
        InjuryType.brokenLeftArm,
      ]);
    });

    testWidgets(
      'an added wound is marked as the innkeeper\'s only when the served '
      'effect says so (D-12)',
      (tester) async {
        await pumpChips(
          tester,
          isRemovalEnabled: true,
          added: const [InjuryType.crushedRightHand, InjuryType.deepCut],
          innkeeperAdded: const [InjuryType.deepCut, InjuryType.severeBurn],
        );

        expect(
          _labelOf(_addedChip(tester, InjuryType.deepCut)),
          InjuryChips.innkeeperLabelOf(InjuryType.deepCut),
        );
        expect(
          _labelOf(_addedChip(tester, InjuryType.crushedRightHand)),
          InjuryType.crushedRightHand.label,
        );
        expect(
          _labelOf(_addedChip(tester, InjuryType.severeBurn)),
          InjuryType.severeBurn.label,
        );
      },
    );

    testWidgets(
      'with removal on the note under the added wounds says they are the '
      'innkeeper\'s (D-12)',
      (tester) async {
        await pumpChips(tester, isRemovalEnabled: true);

        expect(
          tester.widget<Text>(find.byKey(InjuryChips.innkeeperNoteKey)).data,
          'Una ferita aggiunta a mano è dell\'oste: nessuna cura la toglie',
        );
      },
    );

    testWidgets('with removal off the note is absent', (tester) async {
      await pumpChips(tester, isRemovalEnabled: false);

      expect(find.byKey(InjuryChips.innkeeperNoteKey), findsNothing);
      expect(find.text(InjuryChips.addedHeading), findsOneWidget);
    });
  });
}
