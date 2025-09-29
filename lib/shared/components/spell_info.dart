import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../models/spell.dart';

class SpellInfo extends StatelessWidget {
  const SpellInfo({super.key, required this.spell});

  final Spell spell;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: Row(
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CachedSvg(url: spell.energyDamage!.type!.imagePath),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: AutoSizeText(
                  minFontSize: 10,
                  maxFontSize: 20,
                  spell.name!,
                  style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: Row(
            children: [
              SizedBox(height: 50, width: 50, child: CachedSvg(url: spell.useType!.imagePath)),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: AutoSizeText(
                  minFontSize: 10,
                  maxFontSize: 20,
                  spell.energyDamage!.power.toString() ?? "",
                  style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
