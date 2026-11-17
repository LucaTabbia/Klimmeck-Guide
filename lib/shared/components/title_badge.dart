import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Badge di un titolo: sta al posto del suo nome scritto (revisione layout
/// 2026-11-17). Il nome resta per chi usa un lettore di schermo.
class TitleBadge extends StatelessWidget {
  const TitleBadge({
    super.key,
    required this.title,
    this.size = inlineSize,
    this.semanticLabel,
  });

  /// Lato del badge accanto a una riga di testo.
  static const double inlineSize = 28;

  final TitleType title;
  final double size;

  /// Al posto del solo nome del titolo, quando il badge sostituisce una frase.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? title.label,
    image: true,
    child: CachedSvg(url: title.badgePath, width: size, height: size),
  );
}
