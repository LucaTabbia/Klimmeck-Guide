import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Voci del background nell'ordine servito; quelle in [newEntries] portano il
/// sigillo delle aggiunte.
class BackgroundEntries extends StatelessWidget {
  const BackgroundEntries({
    super.key,
    required this.entries,
    this.newEntries = const {},
  });

  static const double _sigilSize = 28;

  final List<String> entries;
  final Set<String> newEntries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, entry) in entries.indexed)
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : KlimmeckGuideTheme.spacingSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (newEntries.contains(entry))
                  const Padding(
                    padding: EdgeInsets.only(
                      right: KlimmeckGuideTheme.spacingSm,
                    ),
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
          ),
      ],
    );
  }
}
