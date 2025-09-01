import 'package:klimmeck_guide/models/character/character_assets.dart';

import 'character_infos.dart';
import 'character_quests.dart';
import 'character_status.dart';

class Character {
  Character({
    required this.id,
    required this.infos,
    required this.status,
    required this.quests,
    required this.assets,
  });

  final String id;
  final CharacterInfos? infos;
  CharacterStatus? status;
  CharacterQuests? quests;
  CharacterAssets? assets;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json["id"],
    infos: json['infos'] != null ? CharacterInfos.fromJson(json['infos']) : null,
    status: json['status'] != null ? CharacterStatus.fromJson(json['status']) : null,
    quests: json['quests'] != null ? CharacterQuests.fromJson(json['quests']) : null,
    assets: json['assets'] != null ? CharacterAssets.fromJson(json['assets']) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "infos": infos?.toJson(),
    "status": status?.toJson(),
    "quests": quests?.toJson(),
    "assets": assets?.toJson(),
  };
}
