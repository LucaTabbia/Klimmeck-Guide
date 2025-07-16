import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';


class ElCheckBox extends StatefulWidget {
  const ElCheckBox({
    super.key,
    required this.onTap,
    required this.width,
    required this.isSelected,
    required this.text,
    required this.height,
  });

  final Function() onTap;
  final String text;
  final bool isSelected;
  final double width;
  final double height;

  @override
  State<ElCheckBox> createState() => _ElCheckBoxState();
}

class _ElCheckBoxState extends State<ElCheckBox> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.onTap(),
      child: AnimatedContainer(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(
                color: widget.isSelected ? KlimmeckGuideTheme.deepNight : KlimmeckGuideTheme.parchment),
            color: widget.isSelected ? KlimmeckGuideTheme.primaryGold : KlimmeckGuideTheme.deepNight,
            boxShadow: widget.isSelected
                ? [const BoxShadow(color: KlimmeckGuideTheme.primaryGold, blurRadius: 5)]
                : null),
        height: widget.height,
        width: (widget.width),
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: AutoSizeText(widget.text,
              minFontSize: 12,
              maxLines: 1,
              style: KlimmeckGuideTheme.instance
                  .bodyMedium),
        ),
      ),
    );
  }
}
