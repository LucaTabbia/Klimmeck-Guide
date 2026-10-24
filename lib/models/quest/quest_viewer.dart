import 'package:equatable/equatable.dart';

import '../character/character.dart';
import '../character/character_quests.dart';
import '../enums/title_type.dart';

class QuestViewer extends Equatable {
  const QuestViewer({
    required this.characterId,
    required this.title,
    required this.quests,
    required this.cityPointIds,
    required this.twitchPoints,
  });

  factory QuestViewer.of({
    required Character character,
    required int? twitchPoints,
    required Set<String>? cityPointIds,
  }) => QuestViewer(
    characterId: character.id,
    title: character.status?.title,
    quests: character.quests,
    cityPointIds: cityPointIds,
    twitchPoints: twitchPoints,
  );

  final String characterId;
  final TitleType? title;
  final CharacterQuests? quests;

  /// POI della città corrente (GetCity); null = città non nota.
  final Set<String>? cityPointIds;

  /// Saldo live di `userUpdated` (Phase 3 D-18); null = sconosciuto.
  final int? twitchPoints;

  @override
  List<Object?> get props => [
    characterId,
    title,
    quests,
    cityPointIds,
    twitchPoints,
  ];
}
