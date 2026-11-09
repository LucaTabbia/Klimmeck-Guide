import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/enemy_portrait_url.dart';

import 'cached_svg.dart';

/// Ritratto di un nemico dal suo `imagePath` (D-03): SVG da [CachedSvg],
/// raster da [CachedNetworkImage]; percorso non risolvibile o download
/// fallito → nessun riquadro (mai un segnaposto nel bundle). Raster: nessuno
/// spinner; SVG: lo spinner di [CachedSvg] mentre carica.
/// Unico widget per il foglio quest e il foglio esiti; un nemico mai sconfitto
/// (`known == false`, D-08) è una sagoma nera; il FE non lo decide (D-09).
class EnemyPortrait extends StatelessWidget {
  const EnemyPortrait({
    super.key,
    required this.imagePath,
    this.height,
    this.cacheManager,
    this.known = true,
  });

  static const String semanticLabel = 'Ritratto del nemico';
  static const String unknownSemanticLabel = 'Sagoma del nemico';

  /// Sagoma nera dell'alfa del ritratto (D-08): stesso riquadro, inchiostro del tema.
  static const ColorFilter silhouetteFilter = ColorFilter.mode(
    KlimmeckGuideTheme.deepNight,
    BlendMode.srcIn,
  );

  final String? imagePath;
  final double? height;

  /// Solo per i test: la cache di default va in rete.
  final BaseCacheManager? cacheManager;

  /// Il personaggio ha già sconfitto questo nemico (BE, D-03); `false` → sagoma nera (D-08).
  final bool known;

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

  Widget _announced(Widget picture) => Semantics(
    label: known ? semanticLabel : unknownSemanticLabel,
    image: true,
    child: known
        ? picture
        : ColorFiltered(colorFilter: silhouetteFilter, child: picture),
  );
}
