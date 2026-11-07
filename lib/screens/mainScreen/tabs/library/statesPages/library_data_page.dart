import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../models/enums/lore_type.dart';
import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

class LibraryDataPage extends StatelessWidget {
  const LibraryDataPage({
    super.key,
    required this.book,
    required this.lore,
    required this.newLoreIds,
    required this.onBack,
  });

  static const String emptyBookLine =
      'Le pagine di questo libro sono ancora bianche.';
  static const Key emptyBookKey = ValueKey('library.emptyBook');

  /// Chiave stabile per sezione (Pitfall 3): una sezione che compare sopra non
  /// sposta lo stato aperto delle altre.
  static Key sectionKeyOf(LoreType type) => ValueKey<LoreType>(type);

  final LibraryBook book;
  final List<Lore> lore;
  final Set<String> newLoreIds;
  final VoidCallback onBack;

  List<({LoreType type, List<Lore> entries})> get _sections => [
    for (final type in book.types)
      (type: type, entries: lore.where((entry) => entry.type == type).toList()),
  ].where((section) => section.entries.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return LibraryBookFrame(
      book: book,
      onBack: onBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sections.isEmpty)
            Text(
              emptyBookLine,
              key: emptyBookKey,
              textAlign: TextAlign.center,
              style: KlimmeckGuideTheme.instance.bodyMedium,
            ),
          for (final section in sections)
            Dropdown(
              key: sectionKeyOf(section.type),
              sectionName: section.type.label,
              data: _LoreList(
                lores: section.entries,
                newLoreIds: newLoreIds,
                newMarkInk: book.newMarkInk,
              ),
            ),
        ],
      ),
    );
  }
}

class _LoreList extends StatelessWidget {
  const _LoreList({
    required this.lores,
    required this.newLoreIds,
    required this.newMarkInk,
  });

  final List<Lore> lores;
  final Set<String> newLoreIds;
  final Color newMarkInk;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: lores.length,
      itemBuilder: (context, index) => LoreCard(
        lore: lores[index],
        isNew: newLoreIds.contains(lores[index].id),
        newMarkInk: newMarkInk,
      ),
    );
  }
}
