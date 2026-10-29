import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';

/// Istantanea della quest risolta (`QuestResultQuest`): il tipo arriva come
/// stringa, un tipo sconosciuto vale `null` e il titolo resta.
class QuestResultQuest extends Equatable {
  const QuestResultQuest({
    required this.id,
    required this.type,
    required this.title,
  });

  final String id;
  final QuestType? type;
  final String title;

  factory QuestResultQuest.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    return QuestResultQuest(
      id: json['id'] as String,
      type: type is String ? QuestType.values.asNameMap()[type] : null,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type?.name,
    'title': title,
  };

  @override
  List<Object?> get props => [id, type, title];
}
