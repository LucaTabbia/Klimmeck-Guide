import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/spell.dart';

class PendingQuest extends Equatable {
  const PendingQuest({
    required this.id,
    required this.startDate,
    required this.waitingTime,
    required this.quest,
    this.pointsSpent,
    this.arrivedAt,
    this.learningSpell,
  });

  final String id;

  /// Nullo mentre il personaggio viaggia verso il marker della quest (BE Phase 8 D-15).
  final DateTime? startDate;

  /// Arrivo sul marker (BE Phase 9, 09-19): `startDate` resta nullo finché il
  /// gruppo non è al completo.
  final DateTime? arrivedAt;
  final int? waitingTime;
  final Quest? quest;
  final int? pointsSpent;

  /// Magia in apprendimento (BE Phase 24, D-26): valorizzata solo nella parte
  /// di apprendimento, quando `startDate` è la fine della ricerca e
  /// `waitingTime` la durata dell'apprendimento.
  final Spell? learningSpell;

  bool get isTravelling => startDate == null && arrivedAt == null;

  bool get isWaitingForParty => startDate == null && arrivedAt != null;

  bool get isLearning => learningSpell != null;

  /// Fine della parte di apprendimento: l'unico conto ammesso al client (D-26).
  DateTime? get learningEndsAt {
    final start = startDate;
    final wait = waitingTime;
    if (!isLearning || start == null || wait == null) return null;
    return start.add(Duration(milliseconds: wait));
  }

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: json["startDate"] != null
        ? DateTime.parse(json["startDate"])
        : null,
    arrivedAt: json["arrivedAt"] != null
        ? DateTime.parse(json["arrivedAt"])
        : null,
    waitingTime: json["waitingTime"] != null
        ? (json["waitingTime"] as num).toInt()
        : null,
    quest: json["quest"] != null ? Quest.fromJson(json["quest"]) : null,
    pointsSpent: (json["pointsSpent"] as num?)?.toInt(),
    learningSpell: _spellFrom(json['learningSpell']),
  );

  static Spell? _spellFrom(Object? json) =>
      json is Map<String, dynamic> ? Spell.fromJson(json) : null;

  Map<String, dynamic> toJson() => {
    "id": id,
    "startDate": startDate?.toIso8601String(),
    "arrivedAt": arrivedAt?.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest?.id,
    "pointsSpent": pointsSpent,
    "learningSpell": learningSpell?.id,
  };

  PendingQuest copyWith({
    String? id,
    DateTime? startDate,
    DateTime? arrivedAt,
    int? waitingTime,
    Quest? quest,
    int? pointsSpent,
    Spell? learningSpell,
  }) {
    return PendingQuest(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      waitingTime: waitingTime ?? this.waitingTime,
      quest: quest ?? this.quest,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      learningSpell: learningSpell ?? this.learningSpell,
    );
  }

  @override
  List<Object?> get props => [
    id,
    startDate,
    arrivedAt,
    waitingTime,
    quest,
    pointsSpent,
    learningSpell,
  ];
}
