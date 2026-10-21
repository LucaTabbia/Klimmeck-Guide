import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required this.entry,
    required this.onTap,
    this.isEnabled = true,
  });

  final SatchelEntry entry;
  final ValueChanged<int> onTap;
  final bool isEnabled;

  bool get _hasBottomBorder => entry.row + entry.rowSpan < SatchelLayout.rows;

  @override
  Widget build(BuildContext context) {
    const gold = BorderSide(
      color: KlimmeckGuideTheme.primaryGold,
      width: SatchelLayout.borderWidth,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => onTap(entry.pageIndex) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: gold,
            bottom: _hasBottomBorder ? gold : BorderSide.none,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: AutoSizeText(
                  entry.label,
                  maxFontSize: 20,
                  minFontSize: 12,
                  style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
                    color: KlimmeckGuideTheme.paleSilver,
                    shadows: KlimmeckGuideTheme.bordersForText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (!isEnabled)
              const IgnorePointer(
                child: ColoredBox(color: KlimmeckGuideTheme.disabledScrim),
              ),
          ],
        ),
      ),
    );
  }
}
