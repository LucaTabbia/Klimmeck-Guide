import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Chi beve, il più grande possibile, che spunta da fuori dal bordo dello
/// schermo (Phase 26 D-09, D-10): SVG da [CachedSvg], raster da
/// [CachedNetworkImage]; nessuna figura se [url] manca.
class PotionDrinkerFigure extends StatelessWidget {
  const PotionDrinkerFigure({
    super.key,
    required this.url,
    required this.peeksFromLeft,
  });

  final String? url;
  final bool peeksFromLeft;

  /// Quota della figura che resta fuori dallo schermo.
  static const double hiddenShare = 0.28;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shift = constraints.maxWidth * hiddenShare;
      return ClipRect(
        child: Transform.translate(
          offset: Offset(peeksFromLeft ? -shift : shift, 0),
          child: Align(
            alignment: peeksFromLeft
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: _picture(constraints.maxHeight),
          ),
        ),
      );
    },
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
