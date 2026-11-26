import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Chi beve, tutto dentro lo schermo, accostato al suo bordo e in piedi
/// sulla sua barra della vita (Phase 26 D-09, D-10): SVG da [CachedSvg], raster da
/// [CachedNetworkImage]; nessuna figura se [url] manca.
class PotionDrinkerFigure extends StatelessWidget {
  const PotionDrinkerFigure({
    super.key,
    required this.url,
    required this.standsOnLeft,
  });

  final String? url;
  final bool standsOnLeft;

  /// Quota dell'altezza disponibile occupata dalla figura.
  static const double heightShare = 0.7;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: standsOnLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      child: _picture(constraints.maxHeight * heightShare),
    ),
  );

  Widget _picture(double height) {
    final source = url;
    if (source == null) return const SizedBox.shrink();
    if (Uri.parse(source).path.toLowerCase().endsWith('.svg')) {
      return CachedSvg(url: source, height: height);
    }
    return CachedNetworkImage(
      imageUrl: source,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
