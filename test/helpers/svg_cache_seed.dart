import 'dart:io';

import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';

/// Pre-popola la cache SVG con un file minimo: senza, `CachedSvg` va in rete.
void seedSvgCache(Iterable<String> assetIds) {
  final svg =
      File('${Directory.systemTemp.createTempSync('kg_svg').path}/seed.svg')
        ..writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
        );
  for (final id in assetIds) {
    SvgCache().add(CloudinaryAssets.url(id), svg);
  }
}
