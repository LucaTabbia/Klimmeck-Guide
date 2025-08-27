import 'package:flutter/material.dart';

import '../../../../../models/enums/lore_type.dart';
import '../components/book_type.dart';

class LibraryInitialPage extends StatelessWidget {
  const LibraryInitialPage({super.key, required this.onTap});

  final Function(List<LoreType>, String, String) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BookType(
                title: "Bestiario",
                imagePath: 'assets/images/library/bestiary.png',
                onTap: () => onTap(
                  [LoreType.enemy, LoreType.animal, LoreType.plant],
                  "Bestiario",
                  "assets/icons/svg/bookmarkRed.svg",
                ),
              ),
              BookType(
                title: "Luoghi",
                imagePath: 'assets/images/library/locations.png',
                onTap: () => onTap(
                  [LoreType.city, LoreType.region, LoreType.state],
                  "Luoghi",
                  "assets/icons/svg/bookmarkGreen.svg",
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BookType(
                title: "Religioni",
                imagePath: 'assets/images/library/religions.png',
                onTap: () => onTap(
                  [LoreType.religion, LoreType.ceremony, LoreType.god],
                  "Religioni",
                  "assets/icons/svg/bookmarkYellow.svg",
                ),
              ),
              BookType(
                title: "Conoscenze",
                imagePath: 'assets/images/library/knowledge.png',
                onTap: () => onTap(
                  [LoreType.character, LoreType.knowledge, LoreType.material],
                  "Conoscenze",
                  "assets/icons/svg/bookmarkBlue.svg",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
