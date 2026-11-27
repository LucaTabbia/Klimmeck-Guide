import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

/// Testo scritto a matita sulle carte (quantità, usi): chi lo mostra decide
/// come compare, di norma con `WrittenInk`.
class PencilText extends StatelessWidget {
  const PencilText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: KlimmeckGuideTheme.instance.signatureText.copyWith(
        shadows: [
          const Shadow(
            offset: Offset(0, 0),
            blurRadius: 0.7,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}
