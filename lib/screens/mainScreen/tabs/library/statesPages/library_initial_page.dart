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
                imagePath:
                    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660651/bestiary_w68j2y.svg',
                onTap: () => onTap(
                  [LoreType.enemy, LoreType.animal, LoreType.plant],
                  "Bestiario",
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683920/bookmarkRed_jms0vk.svg",
                ),
              ),
              BookType(
                title: "Luoghi",
                imagePath:
                    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660653/locations_rpz9fc.svg',
                onTap: () => onTap(
                  [LoreType.city, LoreType.region, LoreType.state],
                  "Luoghi",
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683911/bookmarkGreen_qdtvdj.svg",
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BookType(
                title: "Religioni",
                imagePath:
                    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660649/religions_vwlitf.svg',
                onTap: () => onTap(
                  [LoreType.religion, LoreType.ceremony, LoreType.god],
                  "Religioni",
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683906/bookmarkYellow_z6jbcp.svg",
                ),
              ),
              BookType(
                title: "Conoscenze",
                imagePath:
                    'https://res.cloudinary.com/dzuhywp53/image/upload/v1757660650/knowledge_jhr4ad.svg',
                onTap: () => onTap(
                  [LoreType.character, LoreType.knowledge, LoreType.material],
                  "Conoscenze",
                  "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683915/bookmarkBlue_shxrk6.svg",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
