import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:klimmeck_guide/utils/enemy_portrait_url.dart';

import 'cached_svg.dart';

/// Ritratto di un nemico dal suo `imagePath` (D-03): SVG da [CachedSvg],
/// raster da [CachedNetworkImage]; percorso non risolvibile o download
/// fallito → nessun riquadro (mai un segnaposto nel bundle). Raster: nessuno
/// spinner; SVG: lo spinner di [CachedSvg] mentre carica.
/// Unico widget per il foglio quest e il foglio esiti; la Phase 17 lo scurirà.
class EnemyPortrait extends StatelessWidget {
  const EnemyPortrait({
    super.key,
    required this.imagePath,
    this.height,
    this.cacheManager,
  });

  static const String semanticLabel = 'Ritratto del nemico';

  final String? imagePath;
  final double? height;

  /// Solo per i test: la cache di default va in rete.
  final BaseCacheManager? cacheManager;

  /// Vero quando c'è qualcosa da caricare: chi impagina riserva lo spazio solo allora.
  static bool canShow(String? imagePath) => enemyPortraitUrl(imagePath) != null;

  @override
  Widget build(BuildContext context) {
    final url = enemyPortraitUrl(imagePath);
    if (url == null) return const SizedBox.shrink();
    if (Uri.parse(url).path.toLowerCase().endsWith('.svg')) {
      return _announced(CachedSvg(url: url, height: height));
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: BoxFit.contain,
      cacheManager: cacheManager,
      imageBuilder: (_, image) =>
          _announced(Image(image: image, height: height, fit: BoxFit.contain)),
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _announced(Widget picture) =>
      Semantics(label: semanticLabel, image: true, child: picture);
}
