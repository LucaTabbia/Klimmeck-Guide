import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/unknown_city_modal.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  testWidgets('shows the city name and the unknown line, nothing else (D-11)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        home: const Scaffold(body: UnknownCityModal(cityName: 'Bosa')),
      ),
    );
    await tester.pumpAndSettle();

    expect(UnknownCityModal.line, 'Non conosci ancora questa città.');
    expect(find.text('Bosa'), findsOneWidget);
    expect(find.text('Non conosci ancora questa città.'), findsOneWidget);
    expect(find.byType(CachedSvg), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('fills the paper width and centres the name and the line (D-23)', (
    tester,
  ) async {
    // Stesso incastro del PaperSheetModal: Stack → Padding → SizedBox(height).
    // L'ospite è più largo della riga non spezzata (col font dei test 32 glifi
    // da 18 px = 576 px): a capo, la riga allargherebbe da sola la Column.
    await tester.pumpWidget(
      buildTestApp(
        home: const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: SizedBox(
                    height: 400,
                    child: UnknownCityModal(cityName: 'Bosa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(UnknownCityModal)).width, 700);
    expect(tester.getCenter(find.text('Bosa')).dx, closeTo(400, 1));
    expect(
      tester.getCenter(find.text(UnknownCityModal.line)).dx,
      closeTo(400, 1),
    );
  });
}
