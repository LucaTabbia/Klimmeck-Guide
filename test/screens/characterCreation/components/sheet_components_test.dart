import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/enum_choice_row.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/sheet_row.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/sheet_text_field.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('EnumChoiceRow', () {
    Widget build({
      RaceType? selected,
      bool enabled = true,
      required ValueChanged<RaceType> onSelected,
    }) => buildTestApp(
      home: Scaffold(
        body: EnumChoiceRow<RaceType>(
          values: RaceType.values,
          selected: selected,
          labelOf: (race) => race.label,
          onSelected: onSelected,
          enabled: enabled,
        ),
      ),
    );

    testWidgets('renders one chip per value with its label', (tester) async {
      await tester.pumpWidget(build(onSelected: (_) {}));

      expect(find.byType(ChoiceChip), findsNWidgets(RaceType.values.length));
      expect(find.text('Elfo'), findsOneWidget);
    });

    testWidgets('tapping a chip reports the value', (tester) async {
      RaceType? picked;
      await tester.pumpWidget(build(onSelected: (race) => picked = race));

      await tester.tap(find.text('Elfo'));

      expect(picked, RaceType.elf);
    });

    testWidgets('only the selected value is marked selected', (tester) async {
      await tester.pumpWidget(
        build(selected: RaceType.elf, onSelected: (_) {}),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips.where((chip) => chip.selected), hasLength(1));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Elfo'))
            .selected,
        isTrue,
      );
    });

    testWidgets('does nothing when disabled', (tester) async {
      RaceType? picked;
      await tester.pumpWidget(
        build(enabled: false, onSelected: (race) => picked = race),
      );

      await tester.tap(find.text('Elfo'), warnIfMissed: false);

      expect(picked, isNull);
    });
  });

  group('SheetTextField', () {
    testWidgets('shows error and helper text and forwards changes', (
      tester,
    ) async {
      String? changed;
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: SheetTextField(
              label: 'Nome',
              initialValue: '',
              errorText: 'Errore',
              helperText: 'Aiuto',
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );

      expect(find.text('Errore'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Aria');
      expect(changed, 'Aria');
    });

    testWidgets('keeps typed text when rebuilt with a new error', (
      tester,
    ) async {
      Widget build(String? error) => buildTestApp(
        home: Scaffold(
          body: SheetTextField(
            label: 'Nome',
            initialValue: '',
            errorText: error,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpWidget(build(null));
      await tester.enterText(find.byType(TextField), 'Aria');

      await tester.pumpWidget(build('Errore'));

      expect(find.text('Aria'), findsOneWidget);
      expect(find.text('Errore'), findsOneWidget);
    });

    testWidgets('is not editable when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: SheetTextField(
              label: 'Età',
              initialValue: '',
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });
  });

  testWidgets('SheetRow renders the label with titleMedium and its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        home: const Scaffold(
          body: SheetRow(label: 'Sesso', child: Text('contenuto')),
        ),
      ),
    );

    expect(find.text('contenuto'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Sesso')).style,
      KlimmeckGuideTheme.instance.titleMedium,
    );
  });
}
