import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/animated_pencil_text.dart';

/// Contatore a matita degli usi/quantità, condiviso da carte magia e oggetti
/// (D-21): ogni nuovo [value] viene riscritto a matita sopra il precedente.
class UsagesPencilCounter extends StatelessWidget {
  const UsagesPencilCounter({super.key, required this.value});

  static const Duration _switchDuration = Duration(milliseconds: 400);

  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 25,
      child: Center(
        child: AnimatedSwitcher(
          duration: _switchDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _rewriteTransition,
          layoutBuilder: _stackOldUnderNew,
          child: AnimatedPencilText(
            key: ValueKey<int>(value),
            text: value.toString(),
          ),
        ),
      ),
    );
  }

  static Widget _rewriteTransition(Widget child, Animation<double> animation) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    final scaleIn = Tween<double>(begin: 1.2, end: 1.0).animate(fadeIn);
    return FadeTransition(
      opacity: fadeIn,
      child: ScaleTransition(scale: scaleIn, child: child),
    );
  }

  static Widget _stackOldUnderNew(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }
}
