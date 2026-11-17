import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum TitleType {
  rookie('Recluta', CloudinaryAssets.rookieRank),
  adventurer('Avventuriero', CloudinaryAssets.adventurerRank),
  paladin('Paladino', CloudinaryAssets.paladinRank),
  mage('Mago', CloudinaryAssets.mageRank),
  hero('Eroe', CloudinaryAssets.heroRank),
  legend('Leggenda', CloudinaryAssets.legendRank);

  const TitleType(this.label, this._badgeId);

  /// Nome del titolo: lo legge chi non vede il badge (copy provvisoria, D-19).
  final String label;
  final String _badgeId;

  /// Badge che il giocatore vede al posto del nome (revisione layout
  /// 2026-11-17).
  String get badgePath => CloudinaryAssets.url(_badgeId);
}
