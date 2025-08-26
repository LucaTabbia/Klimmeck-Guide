import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_section.dart';

import '../../../theme/kg_theme.dart';

class MenuBackground extends StatefulWidget {
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
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.opacityAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Opacity(
              opacity: widget.opacityAnimation.value,
              child: SizedBox(
                width: widget.opacityAnimation.value < 1.0 ? 0 : double.infinity,
                child: Image.asset('assets/images/menuBackground.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(
              width: widget.opacityAnimation.value < 1.0 ? 0 : double.infinity,
              height: widget.opacityAnimation.value < 1.0 ? 0 : double.infinity,
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
                          MenuSection("Mappa", onTap: widget.onTap, index: 0),
                          MenuSection("Profilo", onTap: widget.onTap, index: 1),
                          MenuSection("Diario", onTap: widget.onTap, index: 2),
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
                          MenuSection("Libreria", onTap: widget.onTap, index: 3),
                          MenuSection("Bacheca", onTap: widget.onTap, index: 4),
                          MenuSection("Negozio", onTap: widget.onTap, index: 5),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
