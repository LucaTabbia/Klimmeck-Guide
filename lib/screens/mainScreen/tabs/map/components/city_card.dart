import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/kg_button.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../models/city.dart';

class CityCard extends StatefulWidget {
  const CityCard({super.key, required this.city, required this.onTap});

  final City city;
  final VoidCallback onTap;

  @override
  State<CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<CityCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox(
          height: 200,
          width: 200,
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: KlimmeckGuideTheme.parchment,
                    borderRadius: BorderRadius.all(Radius.circular(KlimmeckGuideTheme.radius)),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoSizeText(
                          widget.city.name ?? "",
                          maxFontSize: 18,
                          style: KlimmeckGuideTheme.instance.specialText.copyWith(fontSize: 18),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: KGButton(text: "Informazioni", onTap: () => widget.onTap()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
