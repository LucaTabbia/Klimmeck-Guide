import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/quest/quest_paper_asset.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/quest/quest.dart';

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    required this.quest,
    required this.isTorn,
    required this.onTap,
    required this.randomizer,
  });

  final Quest quest;

  /// Strappato per tutti o per il proprietario (D-08/D-12), deciso dalla Board.
  final bool isTorn;
  final ValueChanged<Quest> onTap;
  final double randomizer;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(quest),
    child: Semantics(
      button: true,
      label: quest.infos?.title,
      child: SizedBox(
        width: randomizer + 150,
        height: randomizer + 150,
        child: CachedSvg(
          url: CloudinaryAssets.url(questPaperAssetId(quest, isTorn: isTorn)),
        ),
      ),
    ),
  );
}
