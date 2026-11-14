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
    this.imprisonedFor,
    this.isOnMission = false,
  });

  factory QuestViewer.of({
    required Character character,
    required int? twitchPoints,
    required Set<String>? cityPointIds,
    Duration? imprisonedFor,
  }) => QuestViewer(
    characterId: character.id,
    title: character.status?.title,
    quests: character.quests,
    cityPointIds: cityPointIds,
    twitchPoints: twitchPoints,
    imprisonedFor: imprisonedFor,
    isOnMission: character.status?.missionInProgress ?? false,
  );

  final String characterId;
  final TitleType? title;
  final CharacterQuests? quests;

  /// POI della città corrente (GetCity); null = città non nota.
  final Set<String>? cityPointIds;

  /// Saldo live di `userUpdated` (Phase 3 D-18); null = sconosciuto.
  final int? twitchPoints;

  /// Tempo che manca alla fine della prigione (quick 261110-cgd); `null` =
  /// libero.
  final Duration? imprisonedFor;

  /// Missione in corso servita dal BE (D-13/D-16): ogni accettazione è bloccata.
  final bool isOnMission;

  @override
  List<Object?> get props => [
    characterId,
    title,
    quests,
    cityPointIds,
    twitchPoints,
    imprisonedFor,
    isOnMission,
  ];
}
