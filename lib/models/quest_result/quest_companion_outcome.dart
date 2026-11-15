import 'package:equatable/equatable.dart';

/// Il compagno nell'esito (BE Phase 23, D-27): servito ogni volta che ha
/// combattuto; nome mostrato già risolto dal backend.
class QuestCompanionOutcome extends Equatable {
  const QuestCompanionOutcome({
    required this.name,
    required this.lifeBefore,
    required this.lifePoints,
    required this.maxLifePoints,
    this.isDefeated = false,
    this.fullLifeAt,
  });

  /// Soggetto delle righe quando il nome servito manca o è vuoto.
  static const String unnamedLabel = 'Il tuo compagno';

  final String name;
  final int lifeBefore;
  final int lifePoints;
  final int maxLifePoints;
  final bool isDefeated;

  /// Istante UTC del ritorno in forze; `null` quando non servito.
  final DateTime? fullLifeAt;

  /// Confine di parsing: senza numeri la voce vale null e l'esito resta; un
  /// nome mancante non toglie la sconfitta né la vita (D-27).
  static QuestCompanionOutcome? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final name = json['name'];
    final lifeBefore = json['lifeBefore'];
    final lifePoints = json['lifePoints'];
    final maxLifePoints = json['maxLifePoints'];
    if (lifeBefore is! num || lifePoints is! num || maxLifePoints is! num) {
      return null;
    }
    return QuestCompanionOutcome(
      name: _nameOf(name),
      lifeBefore: lifeBefore.toInt(),
      lifePoints: lifePoints.toInt(),
      maxLifePoints: maxLifePoints.toInt(),
      isDefeated: json['defeated'] == true,
      fullLifeAt: _instantOf(json['fullLifeAt']),
    );
  }

  static String _nameOf(Object? name) {
    final trimmed = name is String ? name.trim() : '';
    return trimmed.isEmpty ? unnamedLabel : trimmed;
  }

  static DateTime? _instantOf(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'lifeBefore': lifeBefore,
    'lifePoints': lifePoints,
    'maxLifePoints': maxLifePoints,
    'defeated': isDefeated,
    'fullLifeAt': fullLifeAt?.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    name,
    lifeBefore,
    lifePoints,
    maxLifePoints,
    isDefeated,
    fullLifeAt,
  ];
}
