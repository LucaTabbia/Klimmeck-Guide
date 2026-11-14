import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/character_assets.dart';

import 'character_infos.dart';
import 'character_quests.dart';
import 'character_status.dart';

class Character extends Equatable {
  const Character({
    required this.id,
    required this.infos,
    required this.status,
    required this.quests,
    required this.assets,
  });

  final String id;
  final CharacterInfos? infos;
  final CharacterStatus? status;
  final CharacterQuests? quests;
  final CharacterAssets? assets;

  /// Missione in corso servita dal BE (Phase 21 D-12, D-16): unico lettore
  /// del blocco di Diario, Bacheca, borsa e viaggio.
  bool get isOnMission => status?.missionInProgress ?? false;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json["id"],
    infos: json['infos'] != null
        ? CharacterInfos.fromJson(json['infos'])
        : null,
    status: json['status'] != null
        ? CharacterStatus.fromJson(json['status'])
        : null,
    quests: json['quests'] != null
        ? CharacterQuests.fromJson(json['quests'])
        : null,
    assets: json['assets'] != null
        ? CharacterAssets.fromJson(json['assets'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "infos": infos?.toJson(),
    "status": status?.toJson(),
    "quests": quests?.toJson(),
    "assets": assets?.toJson(),
  };

  @override
  List<Object?> get props => [id, infos, status, quests, assets];
}
