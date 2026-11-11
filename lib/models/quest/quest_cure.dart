import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';

/// Cura portata da una quest come premio (BE Phase 18, D-01): un tetto sulla
/// vita massima e le ferite che guarisce. La applica il backend; il FE la
/// mostra soltanto.
class QuestCure extends Equatable {
  const QuestCure({required this.lifePointsShare, required this.canHeal});

  /// Quota della vita massima a cui la quest riporta (0..1).
  final double lifePointsShare;
  final List<InjuryType> canHeal;

  /// Confine di parsing: una cura malformata vale `null` e la quest resta.
  static QuestCure? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final share = json['lifePointsShare'];
    final canHeal = json['canHeal'];
    if (share is! num || !share.isFinite || share < 0 || share > 1) return null;
    if (canHeal is! List) return null;
    return QuestCure(
      lifePointsShare: share.toDouble(),
      canHeal: injuryTypesFrom(canHeal),
    );
  }

  Map<String, dynamic> toJson() => {
    'lifePointsShare': lifePointsShare,
    'canHeal': canHeal.map((type) => type.name).toList(),
  };

  QuestCure copyWith({double? lifePointsShare, List<InjuryType>? canHeal}) =>
      QuestCure(
        lifePointsShare: lifePointsShare ?? this.lifePointsShare,
        canHeal: canHeal ?? this.canHeal,
      );

  @override
  List<Object?> get props => [lifePointsShare, canHeal];
}
