import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pet.dart';

/// Compagno posseduto (BE Phase 19, D-03): il compagno a catalogo più lo
/// stato che vive sul personaggio. Vita, riposo e attesa della pozione
/// arrivano dal backend (BE Phase 23); il FE interpola soltanto (D-09, D-24).
class OwnedPet extends Equatable {
  const OwnedPet({
    required this.pet,
    required this.xp,
    required this.currentLifePoints,
    this.name,
    this.isDefeated = false,
    this.lifeAsOf,
    this.fullLifeAt,
    this.potionRecoveryUntil,
    this.level,
    this.ownMaxLifePoints,
  });

  /// Una voce è `{ pet, xp, currentLifePoints }`: qualsiasi altra forma vale
  /// null e chi la contiene la scarta. Lo stato del compagno è tollerante:
  /// un valore illeggibile vale null o false e la voce resta (D-24).
  static OwnedPet? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final pet = Pet.tryFromEntryJson(json['pet']);
    final xp = json['xp'];
    final life = json['currentLifePoints'];
    if (pet == null || xp is! num || life is! num) return null;
    return OwnedPet(
      pet: pet,
      xp: xp.toInt(),
      currentLifePoints: life.toInt(),
      name: _nameOf(json['name']),
      isDefeated: json['defeated'] == true,
      lifeAsOf: _instantOf(json['lifeAsOf']),
      fullLifeAt: _instantOf(json['fullLifeAt']),
      potionRecoveryUntil: _instantOf(json['potionRecoveryUntil']),
      level: _levelOf(json['level']),
      ownMaxLifePoints: _positiveOf(json['maxLifePoints']),
    );
  }

  static String? _nameOf(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static DateTime? _instantOf(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static int? _levelOf(Object? value) =>
      value is num && value >= 1 ? value.toInt() : null;

  static int? _positiveOf(Object? value) =>
      value is num && value > 0 ? value.toInt() : null;

  final Pet pet;
  final int xp;
  final int currentLifePoints;

  /// Nome scelto dal giocatore (D-18); null = la specie è la dicitura (D-20).
  final String? name;

  /// Sconfitto finché `fullLifeAt` è futura: lo risolve il backend alla
  /// lettura (D-24).
  final bool isDefeated;

  /// Istante in cui vale `currentLifePoints`: l'ancora da cui la vita a
  /// riposo sale; null se equipaggiato o in forze (D-24).
  final DateTime? lifeAsOf;

  /// Istante in cui il compagno a riposo torna alla vita piena; null se
  /// equipaggiato o in forze (D-24).
  final DateTime? fullLifeAt;

  /// Attesa della pozione di questo compagno soltanto (D-05).
  final DateTime? potionRecoveryUntil;

  /// Livello del compagno servito dal BE (D-37); null = nascosto.
  final int? level;

  /// Vita massima del compagno, cresce col livello (D-38); null = quella
  /// della specie.
  final int? ownMaxLifePoints;

  /// L'unica vita massima di un compagno posseduto (D-38): ogni lettore passa
  /// da qui.
  int? get effectiveMaxLifePoints => ownMaxLifePoints ?? pet.maxLifePoints;

  Map<String, dynamic> toJson() => {
    'pet': pet.toJson(),
    'xp': xp,
    'currentLifePoints': currentLifePoints,
    'name': name,
    'defeated': isDefeated,
    'lifeAsOf': lifeAsOf?.toIso8601String(),
    'fullLifeAt': fullLifeAt?.toIso8601String(),
    'potionRecoveryUntil': potionRecoveryUntil?.toIso8601String(),
    'level': level,
    'maxLifePoints': ownMaxLifePoints,
  };

  @override
  List<Object?> get props => [
    pet,
    xp,
    currentLifePoints,
    name,
    isDefeated,
    lifeAsOf,
    fullLifeAt,
    potionRecoveryUntil,
    level,
    ownMaxLifePoints,
  ];
}
