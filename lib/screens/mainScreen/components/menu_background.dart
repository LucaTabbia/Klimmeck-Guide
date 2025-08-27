import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_section.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';

import '../../../theme/kg_theme.dart';

class MenuBackground extends StatelessWidget {
  const MenuBackground({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.opacityAnimation,
  });

  final int selectedIndex;
  final Function(int) onTap;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacityAnimation,
      builder: (context, child) {
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
                    width: 150,
                    height: MediaQuery.of(context).size.height,
                    child: Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 2 + 60),
                      child: AutoSizeText(
                        "Chiudi il menù",
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
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: KlimmeckGuideTheme.primaryGold, width: 2),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MenuSection("Mappa", onTap: onTap, index: 0),
                          MenuSection("Profilo", onTap: onTap, index: 1),
                          MenuSection("Diario", onTap: onTap, index: 2),
                        ],
                      ),
                      Container(
                        width: 456,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: KlimmeckGuideTheme.primaryGold, width: 2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          MenuSection("Libreria", onTap: onTap, index: 3),
                          MenuSection("Bacheca", onTap: onTap, index: 4),
                          MenuSection("Negozio", onTap: onTap, index: 5),
                        ],
                      ),
                    ],
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
