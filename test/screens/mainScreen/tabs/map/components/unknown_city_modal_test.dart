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
}
