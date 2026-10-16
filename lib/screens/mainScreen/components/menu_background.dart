import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class MenuBackground extends StatelessWidget {
  const MenuBackground({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.opacityAnimation,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacityAnimation,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final cellWidth = SatchelLayout.cellWidth(size.width);
        final rowHeight = size.height / SatchelLayout.rows;
        return Opacity(
          opacity: opacityAnimation.value,
          child: BackgroundImage(
            size: opacityAnimation.value == 0 ? 0 : double.infinity,
            child: SizedBox(
              width: opacityAnimation.value == 0 ? 0 : double.infinity,
              height: opacityAnimation.value == 0 ? 0 : double.infinity,
              child: Row(
                children: [
                  SizedBox(
                    width:
                        SatchelLayout.closeColumnWidth -
                        SatchelLayout.borderWidth,
                    height: size.height,
                    child: Padding(
                      padding: EdgeInsets.only(top: size.height / 2 + 60),
                      child: AutoSizeText(
                        'Chiudi il menù',
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
                  Container(
                    height: size.height,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: KlimmeckGuideTheme.primaryGold,
                          width: SatchelLayout.borderWidth,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cellWidth * SatchelLayout.columns,
                    height: size.height,
                    child: Stack(
                      children: [
                        for (final entry in SatchelLayout.entries)
                          Positioned(
                            key: ValueKey('satchel-cell-${entry.pageIndex}'),
                            left: entry.column * cellWidth,
                            top: entry.row * rowHeight,
                            width: cellWidth,
                            height: entry.rowSpan * rowHeight,
                            child: MenuSection(entry: entry, onTap: onTap),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
