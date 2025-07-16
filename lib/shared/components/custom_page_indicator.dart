
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class CustomPageIndicator extends StatefulWidget {
  const CustomPageIndicator({super.key, required this.currentPage});

  final int currentPage;

  @override
  State<CustomPageIndicator> createState() => _CustomPageIndicatorState();
}

class _CustomPageIndicatorState extends State<CustomPageIndicator> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [indicator(0, context), indicator(1, context), indicator(2, context)],
    );
  }

  Widget indicator(int index, BuildContext context) {
    return AnimatedContainer(
      height: widget.currentPage == index ? 14 : 12,
      width: widget.currentPage == index ? 14 : 12,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        border: widget.currentPage != index ? Border.all(color: KlimmeckGuideTheme.parchment) : null,
        color: widget.currentPage == index ? KlimmeckGuideTheme.primaryGold : KlimmeckGuideTheme.deepNight,
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
