import 'package:flutter/material.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';

import '../../theme/kg_theme.dart';
import 'cached_svg.dart';

/// Chip a icone a selezione multipla: nessun chip acceso mostra tutto, ogni
/// chip acceso aggiunge il suo tipo (D-23). I chip si restringono per stare
/// sempre nella larghezza disponibile, senza scorrere. I valori arrivano già
/// filtrati da chi chiama.
class ItemsFilter<T> extends StatelessWidget {
  const ItemsFilter({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.getImage,
  });

  static const double _largestChip = 50;
  static const double _gap = 8;
  static const double _border = 1;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  final List<T> values;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T) getImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chip = _chipSideFor(constraints.maxWidth);
          return Row(
            children: [
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: _buildChip(value, chip),
                ),
            ],
          );
        },
      ),
    );
  }

  double _chipSideFor(double width) {
    if (values.isEmpty) return _largestChip;
    final perChipExtra = _gap + _border * 2;
    final fitting = (width - perChipExtra * values.length) / values.length;
    return fitting.clamp(0, _largestChip).toDouble();
  }

  Widget _buildChip(T value, double side) {
    return GestureDetector(
      onTap: () => onChanged(toggledFilterSelection(selected, value)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(side / 2),
          border: Border.all(
            color: KlimmeckGuideTheme.darkWood,
            width: _border,
          ),
          color: selected.contains(value)
              ? KlimmeckGuideTheme.primaryGold
              : KlimmeckGuideTheme.darkBronze,
        ),
        child: CachedSvg(url: getImage(value), width: side, height: side),
      ),
    );
  }
}
