import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';

import '../../../helpers/test_app.dart';

FilterChip _chip(WidgetTester tester, InjuryType injury) =>
    tester.widget<FilterChip>(
      find.byKey(ValueKey('completion.injury.${injury.name}')),
    );

void main() {
  late List<InjuryType> toggles;

  setUp(() => toggles = []);

  Future<void> pumpChips(
    WidgetTester tester, {
    List<InjuryType> existing = const [InjuryType.blackEye],
    List<InjuryType> added = const [InjuryType.crushedRightHand],
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: SingleChildScrollView(
            child: InjuryChips(
              existing: existing,
              added: added,
              onToggled: toggles.add,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'an injury the character already had is selected and locked (D-14)',
    (tester) async {
      await pumpChips(tester);

      final chip = _chip(tester, InjuryType.blackEye);
      expect(chip.selected, isTrue);
      expect(chip.onSelected, isNull);
    },
  );

  testWidgets('an injury the fight adds is selected and removable (D-14)', (
    tester,
  ) async {
    await pumpChips(tester);

    final chip = _chip(tester, InjuryType.crushedRightHand);
    expect(chip.selected, isTrue);
    expect(chip.onSelected, isNotNull);
    chip.onSelected!(false);

    expect(toggles, [InjuryType.crushedRightHand]);
  });

  testWidgets('an injury not present can be added (D-06)', (tester) async {
    await pumpChips(tester);

    final chip = _chip(tester, InjuryType.brokenLeftArm);
    expect(chip.selected, isFalse);
    chip.onSelected!(true);

    expect(toggles, [InjuryType.brokenLeftArm]);
  });
}
