import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Barra della vita del foglio esiti (Phase 9 D-02): riempimento e numeri
/// nell'inchiostro della perdita, del guadagno o neutro.
class HpDeltaBar extends StatelessWidget {
  const HpDeltaBar({
    super.key,
    required this.hp,
    required this.max,
    this.isLoss = false,
    this.isGain = false,
  });

  static const Key barKey = ValueKey('hpDeltaBar.bar');
  static const Key valueKey = ValueKey('hpDeltaBar.value');
  static const double _trackHeight = 12;
  static const double _borderWidth = 1;

  final double hp;
  final int max;
  final bool isLoss;
  final bool isGain;

  double get _fraction => max <= 0 ? 0 : (hp / max).clamp(0.0, 1.0);

  Color get _ink {
    if (isLoss) return KlimmeckGuideTheme.bloodRed;
    if (isGain) return KlimmeckGuideTheme.healGreen;
    return KlimmeckGuideTheme.darkWood;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KlimmeckGuideTheme.radius);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: barKey,
          height: _trackHeight,
          decoration: BoxDecoration(
            color: KlimmeckGuideTheme.parchment,
            borderRadius: radius,
            border: Border.all(
              color: KlimmeckGuideTheme.darkWood,
              width: _borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _fraction,
                heightFactor: 1,
                child: DecoratedBox(decoration: BoxDecoration(color: _ink)),
              ),
            ),
          ),
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingXs),
        Text(
          '${hp.round()} / $max',
          key: valueKey,
          style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(color: _ink),
        ),
      ],
    );
  }
}
