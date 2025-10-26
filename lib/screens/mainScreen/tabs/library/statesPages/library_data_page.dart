import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

import '../../../../../models/enums/lore_type.dart';
import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

class LibraryDataPage extends StatefulWidget {
  const LibraryDataPage({
    super.key,
    required this.lore,
    required this.onBack,
    required this.types,
    required this.title,
    required this.bookmarkImagePath,
  });

  final List<LoreType> types;
  final String title;
  final String bookmarkImagePath;
  final List<Lore> lore;
  final VoidCallback onBack;

  @override
  State<LibraryDataPage> createState() => _LibraryDataPageState();
}

class _LibraryDataPageState extends State<LibraryDataPage> {
  late List<List<Lore>> _loreLists;

  @override
  void initState() {
    _loreLists = widget.types
        .map((type) => widget.lore.where((lore) => lore.type == type).toList())
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 100,
        decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        widget.title,
                        style: KlimmeckGuideTheme.instance.headlineLarge,
                      ),
                    ),
                    ...List.generate(widget.types.length, (typesIndex) {
                      return Dropdown(
                        sectionName: widget.types[typesIndex].name,
                        data: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...List.generate(_loreLists[typesIndex].length, (
                              loreIndex,
                            ) {
                              return LoreCard(
                                lore: _loreLists[typesIndex][loreIndex],
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () => widget.onBack(),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedSvg(url: widget.bookmarkImagePath),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
