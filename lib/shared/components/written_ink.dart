import 'package:flutter/material.dart';

/// Inchiostro che si scrive e si cancella come un tratto di penna, sempre da
/// sinistra a destra: mentre [stroke] avanza si scopre il bordo destro,
/// mentre torna indietro avanza il bordo sinistro. A zero non disegna nulla.
class WrittenInk extends StatelessWidget {
  const WrittenInk({super.key, required this.stroke, required this.child});

  final Animation<double> stroke;
  final Widget child;

  static const Key clipKey = ValueKey('written_ink');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: stroke,
      builder: (context, ink) {
        if (stroke.value == 0) return const SizedBox.shrink();
        return ClipRect(
          key: clipKey,
          clipper: _InkClipper(
            progress: stroke.value,
            isWiping: stroke.status == AnimationStatus.reverse,
          ),
          child: ink,
        );
      },
      child: child,
    );
  }
}

class _InkClipper extends CustomClipper<Rect> {
  const _InkClipper({required this.progress, required this.isWiping});

  final double progress;
  final bool isWiping;

  @override
  Rect getClip(Size size) => isWiping
      ? Rect.fromLTRB(size.width * (1 - progress), 0, size.width, size.height)
      : Rect.fromLTRB(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_InkClipper oldClipper) =>
      progress != oldClipper.progress || isWiping != oldClipper.isWiping;
}
