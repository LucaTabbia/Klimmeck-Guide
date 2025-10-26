import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/components/cached_svg.dart';
import '../../../../../theme/kg_theme.dart';

class ItemsFilter<T> extends StatelessWidget {
  const ItemsFilter({
    super.key,
    required this.values,
    required this.onTap,
    this.current,
    required this.getImage,
  });

  final List<T> values;
  final Function(T?) onTap;
  final T? current;
  final String Function(T) getImage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onTap(null),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: KlimmeckGuideTheme.darkWood,
                  width: 1,
                ),
                color: current == null
                    ? KlimmeckGuideTheme.primaryGold
                    : KlimmeckGuideTheme.darkBronze,
              ),
              child: Center(
                child: AutoSizeText(
                  "Tutti",
                  style: KlimmeckGuideTheme.instance.specialText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ...values.map(
            (v) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onTap(v),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: KlimmeckGuideTheme.darkWood,
                      width: 1,
                    ),
                    color: current == v
                        ? KlimmeckGuideTheme.primaryGold
                        : KlimmeckGuideTheme.darkBronze,
                  ),
                  child: CachedSvg(url: getImage(v), width: 50, height: 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
