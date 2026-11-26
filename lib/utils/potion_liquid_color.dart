import 'dart:ui';

import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Colore del liquido della boccetta: una tabella fissa per rarità
/// (Phase 26 D-03); rarità ignota = comune.
Color potionLiquidColorOf(RarityType? rarity) => switch (rarity) {
  null || RarityType.common => KlimmeckGuideTheme.potionCommon,
  RarityType.uncommon => KlimmeckGuideTheme.potionUncommon,
  RarityType.rare => KlimmeckGuideTheme.potionRare,
  RarityType.ultrarare => KlimmeckGuideTheme.potionUltrarare,
  RarityType.legendary => KlimmeckGuideTheme.potionLegendary,
};
