import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Chi beve, alto [height] e mai più largo di [maxWidth] (Phase 26 D-09,
/// D-10): SVG da [CachedSvg], raster da [CachedNetworkImage]; nessuna figura
/// se [url] manca.
class PotionDrinkerFigure extends StatelessWidget {
  const PotionDrinkerFigure({
    super.key,
    required this.url,
    required this.height,
    required this.maxWidth,
  });

  final String? url;
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height),
    child: _picture(),
  );

  Widget _picture() {
    final source = url;
    if (source == null) return SizedBox(height: height);
    if (Uri.parse(source).path.toLowerCase().endsWith('.svg')) {
      return CachedSvg(url: source, height: height);
    }
    return CachedNetworkImage(
      imageUrl: source,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, _) => SizedBox(height: height),
      errorWidget: (_, _, _) => SizedBox(height: height),
    );
  }
}
