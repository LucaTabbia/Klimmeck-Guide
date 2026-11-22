import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache_manager.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/transparent_image.dart';
import '../../helpers/test_app.dart';

const _seededId = 'v1/cached_svg_test_seeded.svg';
const _unseededUrl =
    'https://res.cloudinary.com/x/image/upload/v1/cached_svg_test_unseeded.svg';
const _rasterUrl =
    'https://res.cloudinary.com/x/image/upload/v1/cached_svg_test_raster.svg';

void main() {
  Future<void> pumpSvg(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Center(child: CachedSvg(url: url, width: 40, height: 24)),
        ),
      ),
    );
  }

  SizedBox boxOf(WidgetTester tester) => tester.widget<SizedBox>(
    find.descendant(
      of: find.byType(CachedSvg),
      matching: find.byType(SizedBox),
    ),
  );

  testWidgets('shows an empty box of the requested size while the file loads, '
      'never a spinner (D-21)', (tester) async {
    await pumpSvg(tester, _unseededUrl);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final loading = boxOf(tester);
    expect(loading.width, 40);
    expect(loading.height, 24);
    expect(loading.child, isNull);

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('renders the cached file as a picture (D-21)', (tester) async {
    seedSvgCache([_seededId]);

    await pumpSvg(tester, CloudinaryAssets.url(_seededId));
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders a cached raster file as an image', (tester) async {
    final raster = File(
      '${Directory.systemTemp.createTempSync('kg_raster').path}/seed.webp',
    )..writeAsBytesSync(kTransparentImage);
    SvgCache().add(_rasterUrl, raster);

    await pumpSvg(tester, _rasterUrl);

    expect(find.byType(SvgPicture), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as FileImage).file.path, raster.path);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('sizes a raster as the SVG was sized: the height rules and the '
      'width follows the proportions', (tester) async {
    final raster = File(
      '${Directory.systemTemp.createTempSync('kg_raster').path}/seed.webp',
    )..writeAsBytesSync(kTransparentImage);
    SvgCache().add(_rasterUrl, raster);

    await pumpSvg(tester, _rasterUrl);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.height, 24);
    expect(image.width, isNull);
  });

  testWidgets('a raster with the width alone keeps that width', (tester) async {
    final raster = File(
      '${Directory.systemTemp.createTempSync('kg_raster').path}/seed.webp',
    )..writeAsBytesSync(kTransparentImage);
    SvgCache().add(_rasterUrl, raster);

    await tester.pumpWidget(
      buildTestApp(
        home: const Scaffold(
          body: Center(child: CachedSvg(url: _rasterUrl, width: 40)),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 40);
    expect(image.height, isNull);
  });

  test('keeps 2000 objects in the SVG cache (D-22)', () {
    // The manager itself is not built here: its constructor opens the
    // path_provider channel, absent under `flutter test`.
    expect(SvgCacheManager.maxObjects, 2000);
  });
}
