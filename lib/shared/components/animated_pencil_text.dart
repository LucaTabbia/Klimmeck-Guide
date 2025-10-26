import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class AnimatedPencilText extends StatefulWidget {
  final String text;
  const AnimatedPencilText({super.key, required this.text});

  @override
  State<AnimatedPencilText> createState() => AnimatedPencilTextState();
}

class AnimatedPencilTextState extends State<AnimatedPencilText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut.drive(Tween(begin: 0, end: 1)),
      child: AutoSizeText(
        textAlign: TextAlign.center,
        widget.text,
        style: KlimmeckGuideTheme.instance.signatureText.copyWith(
          shadows: [
            const Shadow(
              offset: Offset(0, 0),
              blurRadius: 0.7,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}
