import 'package:equatable/equatable.dart';

/// Ferito in attesa di soccorso (BE Phase 9 §6, 09-CONTEXT D-16): quest
/// fallita, aid creata per il combattimento perso e istante UTC del fallimento.
class AwaitingAid extends Equatable {
  const AwaitingAid({
    required this.questId,
    required this.aidQuestId,
    required this.since,
  });

  final String questId;
  final String aidQuestId;
  final DateTime since;

  factory AwaitingAid.fromJson(Map<String, dynamic> json) => AwaitingAid(
    questId: json['quest'] as String,
    aidQuestId: json['aidQuest'] as String,
    since: DateTime.parse(json['since'] as String).toUtc(),
  );

  /// Confine di parsing: un valore malformato vale `null`, lo status sopravvive.
  static AwaitingAid? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return AwaitingAid.fromJson(json);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'quest': questId,
    'aidQuest': aidQuestId,
    'since': since.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [questId, aidQuestId, since];
}
