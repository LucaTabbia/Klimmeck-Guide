import 'package:equatable/equatable.dart';

class AbandonQuestRequest extends Equatable {
  const AbandonQuestRequest({required this.id, required this.questId});

  /// Id del personaggio corrente (mai digitato dall'utente).
  final String id;
  final String questId;

  Map<String, dynamic> toJson() => {'id': id, 'questId': questId};

  @override
  List<Object?> get props => [id, questId];
}
