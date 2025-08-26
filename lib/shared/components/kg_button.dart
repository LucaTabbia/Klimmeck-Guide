import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class KGButton extends StatelessWidget {
  final String text;
  final GestureTapCallback onTap;
  final double? width;
  final Color? color;

  const KGButton({super.key, required this.text, required this.onTap, this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KlimmeckGuideTheme.parchment,
          border: Border.all(color: KlimmeckGuideTheme.darkBronze),
          borderRadius: const BorderRadius.all(Radius.circular(KlimmeckGuideTheme.radius)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
          child: Center(
            child: AutoSizeText(
              text,
              maxFontSize: 16,
              maxLines: 1,
              style: KlimmeckGuideTheme.instance.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
