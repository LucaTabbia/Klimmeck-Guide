import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Sigillo di ceralacca che segnala un'aggiunta non ancora vista.
class NewEntrySigil extends StatelessWidget {
  const NewEntrySigil({super.key, this.size = 32});

  static final String url = CloudinaryAssets.url(
    CloudinaryAssets.newEntrySigil,
  );

  final double size;

  @override
  Widget build(BuildContext context) =>
      CachedSvg(url: url, width: size, height: size);
}

/// Sovrappone il sigillo a [child] quando la voce è un'aggiunta non ancora
/// vista. [corner] è l'angolo in alto a destra della carta dentro [child]: il
/// sigillo vi si appoggia senza coprire i tocchi.
class NewEntryMarked extends StatelessWidget {
  const NewEntryMarked({
    super.key,
    required this.isNew,
    required this.corner,
    required this.child,
  });

  static const double sigilSize = 30;

  final bool isNew;
  final Offset corner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isNew) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: corner.dx - sigilSize * 2 / 3,
          top: corner.dy - sigilSize / 3,
          child: const IgnorePointer(child: NewEntrySigil(size: sigilSize)),
        ),
      ],
    );
  }
}
