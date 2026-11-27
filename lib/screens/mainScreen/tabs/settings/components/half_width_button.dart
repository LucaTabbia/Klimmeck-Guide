import 'package:flutter/material.dart';

/// Pulsante delle impostazioni: occupa metà della larghezza, al centro.
class HalfWidthButton extends StatelessWidget {
  const HalfWidthButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Center(child: FractionallySizedBox(widthFactor: 0.5, child: child));
}
