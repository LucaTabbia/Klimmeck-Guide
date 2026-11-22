import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Voci del background nell'ordine servito, divise da una linea corta al
/// centro; quelle in [newEntries] portano il sigillo delle aggiunte.
class BackgroundEntries extends StatelessWidget {
  const BackgroundEntries({
    super.key,
    required this.entries,
    this.newEntries = const {},
  });

  static const Key separatorKey = ValueKey('background.separator');

  static const double _sigilSize = 28;
  static const double _separatorWidthFactor = 0.3;
  static const double _separatorThickness = 1;
  static const double _separatorOpacity = 0.4;

  final List<String> entries;
  final Set<String> newEntries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0) const _Separator(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (newEntries.contains(entry))
                const Padding(
                  padding: EdgeInsets.only(right: KlimmeckGuideTheme.spacingSm),
                  child: NewEntrySigil(size: _sigilSize),
                ),
              Expanded(
                child: Text(
                  entry,
                  style: KlimmeckGuideTheme.instance.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: KlimmeckGuideTheme.spacingSm,
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: BackgroundEntries._separatorWidthFactor,
          child: Container(
            key: BackgroundEntries.separatorKey,
            height: BackgroundEntries._separatorThickness,
            color: KlimmeckGuideTheme.darkWood.withValues(
              alpha: BackgroundEntries._separatorOpacity,
            ),
          ),
        ),
      ),
    );
  }
}
