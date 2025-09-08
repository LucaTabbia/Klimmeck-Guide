import 'dart:ui';

import '../../theme/kg_theme.dart';

enum RarityType {
  common(color: KlimmeckGuideTheme.deepNight),
  uncommon(color: KlimmeckGuideTheme.mysticBlue),
  rare(color: KlimmeckGuideTheme.bloodRed),
  ultrarare(color: KlimmeckGuideTheme.arcanePurple),
  legendary(color: KlimmeckGuideTheme.darkBronze);

  final Color color;

  const RarityType({required this.color});
}
