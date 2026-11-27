import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const _rowHeight = 40.0;

Widget _longList() => Column(
  children: [
    for (var i = 0; i < 40; i++)
      SizedBox(height: _rowHeight, child: Text('Voce $i')),
  ],
);

Finder get _sheet => find.byKey(PaperSheetModal.sheetKey);

ScrollPosition _listPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(Dropdown),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

double _sheetTop(WidgetTester tester) => tester.getTopLeft(_sheet).dy;

ScrollPosition _sheetPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: _sheet, matching: find.byType(Scrollable)).first,
    )
    .position;

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.bottomEmptySheet]));

  Future<void> pumpSheet(WidgetTester tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: PaperSheetModal(
            child: Column(
              children: [
                Dropdown(
                  sectionName: 'Merce',
                  isOpen: true,
                  maxHeight: 300,
                  data: _longList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dragOnList(WidgetTester tester, double dy) async {
    await tester.dragFrom(tester.getCenter(find.text('Voce 1')), Offset(0, dy));
    await tester.pumpAndSettle();
  }

  Future<void> raiseToFull(WidgetTester tester) async {
    await dragOnList(tester, -tester.view.physicalSize.height);
    expect(_sheetTop(tester), lessThanOrEqualTo(0));
  }

  testWidgets('a drag on the list of a half sheet raises the sheet first', (
    tester,
  ) async {
    await pumpSheet(tester);
    final halfTop = _sheetTop(tester);

    await dragOnList(tester, -100);

    expect(_sheetTop(tester), lessThan(halfTop - 50));
    expect(_listPosition(tester).pixels, 0);
  });

  testWidgets('once the sheet is full a drag scrolls the list', (tester) async {
    await pumpSheet(tester);
    await raiseToFull(tester);

    await dragOnList(tester, -100);

    expect(_listPosition(tester).pixels, greaterThan(0));
  });

  testWidgets('pulling the list down from its top lowers the full sheet', (
    tester,
  ) async {
    await pumpSheet(tester);
    await raiseToFull(tester);
    final fullTop = _sheetTop(tester);
    expect(_listPosition(tester).pixels, 0);

    await dragOnList(tester, 120);

    expect(_sheetTop(tester), greaterThan(fullTop + 50));
  });

  testWidgets(
    'pulling the list down scrolls the paper back to its top before the '
    'sheet lowers',
    (tester) async {
      await pumpSheet(tester);
      await raiseToFull(tester);
      final fullTop = _sheetTop(tester);
      await tester.dragFrom(
        tester.getCenter(find.text('Merce')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      final scrolledPaper = _sheetPosition(tester).pixels;
      expect(scrolledPaper, greaterThan(50));

      await tester.dragFrom(
        tester.getCenter(find.text('Voce 3')),
        const Offset(0, 40),
      );
      await tester.pumpAndSettle();

      expect(_sheetTop(tester), fullTop);
      expect(_sheetPosition(tester).pixels, lessThan(scrolledPaper));
    },
  );

  testWidgets('a list pushed past its end scrolls the paper on', (
    tester,
  ) async {
    await pumpSheet(tester);
    await raiseToFull(tester);
    expect(_sheetPosition(tester).pixels, 0);

    await dragOnList(tester, -2000);

    final list = _listPosition(tester);
    expect(list.pixels, list.maxScrollExtent);
    expect(_sheetPosition(tester).pixels, greaterThan(0));
  });

  testWidgets('the full sheet stops before its rolled lower edge', (
    tester,
  ) async {
    await pumpSheet(tester);
    await raiseToFull(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    await tester.dragFrom(
      tester.getCenter(find.text('Merce')),
      Offset(0, -screen.height * 3),
    );
    await tester.pumpAndSettle();

    expect(
      _sheetPosition(tester).pixels,
      closeTo(
        screen.width * PaperSheetModal.visiblePaperFraction - screen.height,
        1,
      ),
    );
  });

  testWidgets('a dropdown outside a sheet scrolls its list freely', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Dropdown(
            sectionName: 'Merce',
            isOpen: true,
            maxHeight: 300,
            data: _longList(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await dragOnList(tester, -100);

    expect(_listPosition(tester).pixels, greaterThan(0));
  });

  testWidgets('the list of a dropdown scrolls right up to its header line', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Dropdown(
            sectionName: 'Merce',
            isOpen: true,
            maxHeight: 300,
            data: _longList(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(Dropdown),
      matching: find.byType(Scrollable),
    );

    expect(
      tester.getTopLeft(list).dy,
      tester.getBottomLeft(find.byType(DropdownHeader)).dy,
    );
  });
}
