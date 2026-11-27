import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ombra di contatto sotto un oggetto appoggiato sul bancone: un ovale
/// sfocato che lo fa posare sul legno invece di galleggiare.
class CounterShadow extends StatelessWidget {
  const CounterShadow({
    super.key,
    required this.width,
    required this.height,
    this.strength = 1,
  });

  final double width;
  final double height;

  /// Quanto pesa l'ombra, da 0 (assente) a 1 (piena): un foglio piatto
  /// ne getta meno di un oggetto voluminoso.
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.elliptical(width / 2, height / 2),
          ),
          boxShadow: [
            BoxShadow(
              color: KlimmeckGuideTheme.counterShadow.withValues(
                alpha: KlimmeckGuideTheme.counterShadow.a * strength,
              ),
              blurRadius: height * 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ombra di un foglio posato piatto sul bancone: ricalca la sagoma della
/// carta e la sfuma appena su tutti i lati, un poco più verso il basso.
class PaperShadow extends StatelessWidget {
  const PaperShadow({
    super.key,
    required this.width,
    required this.height,
    this.strength = 1,
  });

  final double width;
  final double height;

  /// Quanto pesa l'ombra, da 0 (assente) a 1 (piena).
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.08),
          boxShadow: [
            BoxShadow(
              color: KlimmeckGuideTheme.counterShadow.withValues(
                alpha: KlimmeckGuideTheme.counterShadow.a * strength,
              ),
              blurRadius: height * 0.18,
              spreadRadius: height * 0.02,
              offset: Offset(0, height * 0.06),
            ),
          ],
        ),
      ),
    );
  }
}
