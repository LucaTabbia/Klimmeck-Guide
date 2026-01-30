import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';

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
                imagePath: CloudinaryAssets.url(CloudinaryAssets.bestiary),
                onTap: () => onTap(
                  [LoreType.enemy, LoreType.animal, LoreType.plant],
                  "Bestiario",
                  CloudinaryAssets.url(CloudinaryAssets.bookmarkRed),
                ),
              ),
              BookType(
                title: "Luoghi",
                imagePath: CloudinaryAssets.url(CloudinaryAssets.locations),
                onTap: () => onTap(
                  [LoreType.city, LoreType.region, LoreType.state],
                  "Luoghi",
                  CloudinaryAssets.url(CloudinaryAssets.bookmarkGreen),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BookType(
                title: "Religioni",
                imagePath: CloudinaryAssets.url(CloudinaryAssets.religions),
                onTap: () => onTap(
                  [LoreType.religion, LoreType.ceremony, LoreType.god],
                  "Religioni",
                  CloudinaryAssets.url(CloudinaryAssets.bookmarkYellow),
                ),
              ),
              BookType(
                title: "Conoscenze",
                imagePath: CloudinaryAssets.url(CloudinaryAssets.knowledge),
                onTap: () => onTap(
                  [LoreType.character, LoreType.knowledge, LoreType.material],
                  "Conoscenze",
                  CloudinaryAssets.url(CloudinaryAssets.bookmarkBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
