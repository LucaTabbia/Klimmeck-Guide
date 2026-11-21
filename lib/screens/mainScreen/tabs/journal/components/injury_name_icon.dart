import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class InjuryNameIcon extends StatelessWidget {
  const InjuryNameIcon({
    super.key,
    required this.injury,
    this.note,
    this.noteKey,
  });

  static const double _iconSize = 50;

  final InjuryType injury;

  /// Riga sotto il nome della ferita; assente = solo il nome.
  final String? note;
  final Key? noteKey;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _iconSize),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final effect in injury.effects)
            CachedSvg(
              url: effect.imagePath,
              height: _iconSize,
              width: _iconSize,
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    injury.label,
                    style: KlimmeckGuideTheme.instance.bodyMedium,
                  ),
                  if (note != null)
                    Text(
                      note,
                      key: noteKey,
                      style: KlimmeckGuideTheme.instance.errorText,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
