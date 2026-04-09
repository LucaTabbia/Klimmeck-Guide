import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest/quest_infos.dart';
import 'package:klimmeck_guide/models/quest/quest_prizes.dart';
import 'package:klimmeck_guide/models/quest/quest_requirements.dart';

import '../character/character.dart';

class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.infos,
    required this.requirements,
    required this.registeredAdventurers,
    required this.prizes,
  });

  final String id;
  final QuestInfos? infos;
  final QuestRequirements? requirements;
  final QuestPrizes? prizes;
  final List<Character>? registeredAdventurers;

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json["id"],
    infos: json["infos"] != null ? QuestInfos.fromJson(json['infos']) : null,
    requirements: json["requirements"] != null
        ? QuestRequirements.fromJson(json['requirements'])
        : null,
    prizes: json["prizes"] != null
        ? QuestPrizes.fromJson(json['prizes'])
        : null,
    registeredAdventurers: json['registeredAdventurers'] != null
        ? List<Character>.from(
            json['registeredAdventurers'].map((x) => Character.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "infos": infos?.toJson(),
    "requirements": requirements?.toJson(),
    "prizes": prizes?.toJson(),
    "registeredAdventurers": registeredAdventurers?.map((s) => s.id).toList(),
  };

  Quest copyWith({
    String? id,
    QuestInfos? infos,
    QuestRequirements? requirements,
    QuestPrizes? prizes,
    List<Character>? registeredAdventurers,
  }) {
    return Quest(
      id: id ?? this.id,
      infos: infos ?? this.infos,
      requirements: requirements ?? this.requirements,
      prizes: prizes ?? this.prizes,
      registeredAdventurers:
          registeredAdventurers ?? this.registeredAdventurers,
    );
  }

  @override
  List<Object?> get props => [
    id,
    infos,
    requirements,
    prizes,
    registeredAdventurers,
  ];
}
