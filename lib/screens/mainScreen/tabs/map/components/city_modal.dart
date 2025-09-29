import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../models/lore.dart';

class CityModal extends StatefulWidget {
  const CityModal({super.key, required this.lore});

  final Lore lore;

  @override
  State<CityModal> createState() => _CityModalState();
}

class _CityModalState extends State<CityModal> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 7),
        if (widget.lore.image != null) CachedSvg(url: widget.lore.image!, width: 200, height: 200),
        AutoSizeText(
          widget.lore.name ?? "",
          maxFontSize: 24,
          minFontSize: 16,
          textAlign: TextAlign.center,
          style: KlimmeckGuideTheme.instance.specialText.copyWith(fontSize: 24),
        ),

        const SizedBox(height: 20),

        AutoSizeText(
          widget.lore.description ?? "",
          maxFontSize: 18,
          minFontSize: 12,
          textAlign: TextAlign.left,
          style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
            fontSize: 18,
            height: 1.5, // Better line height for readability
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
