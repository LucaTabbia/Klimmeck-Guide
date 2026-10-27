import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';

import 'landscape.dart';
import 'svg_cache_seed.dart';
import 'test_app.dart';

/// SVG usati dalle carte magia dei fixture (sfondo, segnalibro, fuoco, tipi d'uso, foglio, freccia del Dropdown).
void seedSpellSvgs() => seedSvgCache([
  CloudinaryAssets.emptyCardSheet,
  CloudinaryAssets.bookmarkRed,
  CloudinaryAssets.fireEnergy,
  CloudinaryAssets.attackUse,
  CloudinaryAssets.defenseUse,
  CloudinaryAssets.controlUse,
  CloudinaryAssets.illusionUse,
  CloudinaryAssets.charmUse,
  CloudinaryAssets.confuseUse,
  CloudinaryAssets.enhanceUse,
  CloudinaryAssets.infuseUse,
  CloudinaryAssets.emptySheet,
  CloudinaryAssets.arrowDown,
]);

Widget _unwrapped(Widget body) => body;

/// Contenuto della sezione in una colonna scrollabile a larghezza fissa (Pitfall 7).
///
/// [wrap] avvolge il corpo (es. `MultiBlocProvider`/`RepositoryProvider`) senza
/// legare l'helper a un tipo di provider. Non attende la fine delle animazioni:
/// chi chiama decide tra `pump` e `pumpAndSettle`.
Future<void> pumpSpellsHarness(
  WidgetTester tester,
  Widget child, {
  Widget Function(Widget body) wrap = _unwrapped,
}) async {
  useLandscapePhone(tester);
  seedSpellSvgs();
  final body = Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 600, child: child)),
  );
  await tester.pumpWidget(buildTestApp(home: wrap(body)));
}
