import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

class _PendingCacheManager extends Mock implements BaseCacheManager {}

const _rasterUrl = 'https://res.cloudinary.com/x/image/upload/v1/goblin.png';

void main() {
  late _PendingCacheManager cache;

  setUp(() {
    cache = _PendingCacheManager();
    when(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => StreamController<FileResponse>().stream);
  });

  Future<void> pumpPortrait(
    WidgetTester tester,
    String? imagePath, {
    bool known = true,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: EnemyPortrait(
            imagePath: imagePath,
            height: 48,
            cacheManager: cache,
            known: known,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void expectNoImage() {
    expect(find.byType(CachedSvg), findsNothing);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Image), findsNothing);
  }

  testWidgets('an unresolvable path renders nothing (D-03)', (tester) async {
    await pumpPortrait(tester, 'assets/images/goblin.png');

    expectNoImage();
    expect(EnemyPortrait.canShow('assets/images/goblin.png'), isFalse);
  });

  testWidgets('a null path renders nothing (D-03)', (tester) async {
    await pumpPortrait(tester, null);

    expectNoImage();
    expect(EnemyPortrait.canShow(null), isFalse);
  });

  testWidgets('an SVG path renders through CachedSvg (D-03)', (tester) async {
    seedSvgCache(['v1/goblin_test.svg']);

    await pumpPortrait(tester, 'v1/goblin_test.svg');

    final svg = tester.widget<CachedSvg>(find.byType(CachedSvg));
    expect(svg.url, CloudinaryAssets.url('v1/goblin_test.svg'));
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(EnemyPortrait.canShow('v1/goblin_test.svg'), isTrue);
  });

  testWidgets('a raster URL renders through CachedNetworkImage with the '
      'injected cache (D-03)', (tester) async {
    await pumpPortrait(tester, _rasterUrl);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, _rasterUrl);
    expect(image.fit, BoxFit.contain);
    expect(image.cacheManager, same(cache));
    expect(find.byType(CachedSvg), findsNothing);
  });

  testWidgets('the raster placeholder and error are empty boxes, never a '
      'spinner (D-03)', (tester) async {
    await pumpPortrait(tester, _rasterUrl);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final context = tester.element(find.byType(CachedNetworkImage));
    final placeholder = image.placeholder!(context, _rasterUrl);
    final error = image.errorWidget!(context, _rasterUrl, Exception('404'));

    for (final box in [placeholder, error]) {
      expect(box, isA<SizedBox>());
      expect((box as SizedBox).width, 0);
      expect(box.height, 0);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a shown SVG portrait carries a semantic label (D-03)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    seedSvgCache(['v1/goblin_test.svg']);

    await pumpPortrait(tester, 'v1/goblin_test.svg');

    expect(find.bySemanticsLabel(EnemyPortrait.semanticLabel), findsOneWidget);
    expect(EnemyPortrait.semanticLabel, 'Ritratto del nemico');
    semantics.dispose();
  });

  testWidgets('a raster portrait still loading announces no image (D-03)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpPortrait(tester, _rasterUrl);

    expect(find.bySemanticsLabel(EnemyPortrait.semanticLabel), findsNothing);
    semantics.dispose();
  });

  group('silhouette (BE Phase 16)', () {
    const silhouette = ColorFilter.mode(
      KlimmeckGuideTheme.deepNight,
      BlendMode.srcIn,
    );

    testWidgets('an unknown enemy is a black silhouette of the SVG portrait '
        '(D-08)', (tester) async {
      seedSvgCache(['v1/goblin_test.svg']);

      await pumpPortrait(tester, 'v1/goblin_test.svg', known: false);

      final filtered = find.descendant(
        of: find.byType(EnemyPortrait),
        matching: find.byType(ColorFiltered),
      );
      expect(filtered, findsOneWidget);
      expect(tester.widget<ColorFiltered>(filtered).colorFilter, silhouette);
      expect(EnemyPortrait.silhouetteFilter, silhouette);
      final svg = find.descendant(
        of: filtered,
        matching: find.byType(CachedSvg),
      );
      expect(svg, findsOneWidget);
      expect(tester.widget<CachedSvg>(svg).height, 48);
    });

    testWidgets("a known enemy keeps today's portrait (D-08)", (tester) async {
      seedSvgCache(['v1/goblin_test.svg']);

      await pumpPortrait(tester, 'v1/goblin_test.svg');

      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(CachedSvg), findsOneWidget);
    });

    testWidgets('the silhouette announces itself as «Sagoma del nemico» '
        '(D-17)', (tester) async {
      final semantics = tester.ensureSemantics();
      seedSvgCache(['v1/goblin_test.svg']);

      await pumpPortrait(tester, 'v1/goblin_test.svg', known: false);

      expect(find.bySemanticsLabel('Sagoma del nemico'), findsOneWidget);
      expect(find.bySemanticsLabel('Ritratto del nemico'), findsNothing);
      expect(EnemyPortrait.unknownSemanticLabel, 'Sagoma del nemico');
      semantics.dispose();
    });

    testWidgets('an unknown raster portrait is a silhouette too (D-08)', (
      tester,
    ) async {
      await pumpPortrait(tester, _rasterUrl, known: false);

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final built = image.imageBuilder!(
        tester.element(find.byType(CachedNetworkImage)),
        MemoryImage(Uint8List(0)),
      );

      expect(built, isA<Semantics>());
      final announced = built as Semantics;
      expect(announced.properties.label, 'Sagoma del nemico');
      expect(announced.child, isA<ColorFiltered>());
      final filtered = announced.child! as ColorFiltered;
      expect(filtered.colorFilter, silhouette);
      expect(filtered.child, isA<Image>());
    });

    testWidgets('no portrait path still renders nothing when unknown (D-08)', (
      tester,
    ) async {
      await pumpPortrait(tester, null, known: false);

      expectNoImage();
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });
}
