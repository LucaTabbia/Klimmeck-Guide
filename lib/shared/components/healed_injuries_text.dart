import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';
import '../../utils/item_lines.dart';

/// Riga «Cura: …» di un oggetto heal: le ferite che nessuna cura toglie a chi
/// legge sono scritte in rosso (D-21), quelle che chi legge ha e l'oggetto
/// cura in verde (Phase 26), il resto nello stile della riga; il testo letto
/// è prefisso, etichette e virgole, senza altro.
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
  static const TextStyle _curableStyle = TextStyle(
    color: KlimmeckGuideTheme.healGreen,
  );

  static TextStyle? _styleOf(HealedInjuryMark mark) => switch (mark) {
    HealedInjuryMark.plain => null,
    HealedInjuryMark.curable => _curableStyle,
    HealedInjuryMark.beyondCure => _beyondCureStyle,
  };

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: healedInjuriesPrefix,
      children: [
        for (final (index, injury) in labels.indexed) ...[
          if (index > 0) const TextSpan(text: healedInjuriesSeparator),
          TextSpan(text: injury.label, style: _styleOf(injury.mark)),
        ],
      ],
    ),
    style: style,
    textAlign: textAlign,
  );
}
