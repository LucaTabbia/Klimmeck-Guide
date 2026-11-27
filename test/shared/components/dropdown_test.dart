import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

import '../../helpers/landscape.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

Widget _longList() => Column(
  children: [
    for (var i = 0; i < 40; i++) SizedBox(height: 40, child: Text('Voce $i')),
  ],
);

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.arrowDown]));

  Future<void> pumpDropdown(WidgetTester tester, {double? maxHeight}) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Dropdown(
              sectionName: 'Merce',
              isOpen: true,
              maxHeight: maxHeight,
              pinned: const SizedBox(height: 30, child: Text('Filtri')),
              data: _longList(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pinned row stays under the header while the list scrolls', (
    tester,
  ) async {
    await pumpDropdown(tester, maxHeight: 300);
    final pinnedTop = tester.getTopLeft(find.text('Filtri')).dy;
    final list = find.descendant(
      of: find.byType(Dropdown),
      matching: find.byType(Scrollable),
    );

    expect(pinnedTop, greaterThan(tester.getTopLeft(find.text('Merce')).dy));
    expect(
      tester.getTopLeft(list).dy,
      tester.getBottomLeft(find.text('Filtri')).dy,
    );

    await tester.dragFrom(
      tester.getCenter(find.text('Voce 2')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Filtri')).dy, pinnedTop);
    expect(tester.state<ScrollableState>(list).position.pixels, greaterThan(0));
  });

  testWidgets('without a height limit the pinned row heads the content', (
    tester,
  ) async {
    await pumpDropdown(tester);

    expect(
      tester.getTopLeft(find.text('Filtri')).dy,
      lessThan(tester.getTopLeft(find.text('Voce 0')).dy),
    );
  });
}
