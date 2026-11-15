import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Vita dopo uno scontro fra `minLifeAfterFight` e il massimo servito, con il
/// testo «x / max» (D-06, D-17). Pitfall 9: con un solo punto vita lo slider
/// non ha divisioni, resta il testo.
class LifeSlider extends StatelessWidget {
  const LifeSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.sliderKey,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (max > minLifeAfterFight)
          Slider(
            key: sliderKey,
            min: minLifeAfterFight.toDouble(),
            max: max.toDouble(),
            divisions: max - minLifeAfterFight,
            value: value.clamp(minLifeAfterFight, max).toDouble(),
            label: '$value',
            onChanged: (life) => onChanged(life.round()),
          ),
        Text('$value / $max', style: KlimmeckGuideTheme.instance.bodyMedium),
      ],
    );
  }
}
