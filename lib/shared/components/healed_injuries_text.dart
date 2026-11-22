import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';
import '../../utils/item_lines.dart';

/// Riga «Cura: …» di un oggetto heal: le ferite che nessuna cura toglie a chi
/// legge sono scritte in rosso (D-21), il resto nello stile della riga; il
/// testo letto resta quello di [healedInjuriesLine].
class HealedInjuriesText extends StatelessWidget {
  const HealedInjuriesText({
    super.key,
    required this.labels,
    this.style,
    this.textAlign,
  });

  final List<HealedInjuryLabel> labels;
  final TextStyle? style;
  final TextAlign? textAlign;

  static const TextStyle _beyondCureStyle = TextStyle(
    color: KlimmeckGuideTheme.bloodRed,
  );

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: healedInjuriesPrefix,
      children: [
        for (final (index, injury) in labels.indexed) ...[
          if (index > 0) const TextSpan(text: healedInjuriesSeparator),
          TextSpan(
            text: injury.label,
            style: injury.isBeyondCure ? _beyondCureStyle : null,
          ),
        ],
      ],
    ),
    style: style,
    textAlign: textAlign,
  );
}
