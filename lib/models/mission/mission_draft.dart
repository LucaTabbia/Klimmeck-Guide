import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/mission/mission_entries.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/utc_instant.dart';

/// Passo raggiunto dal wizard, salvato sulla bozza (D-18).
enum MissionDraftStep { teleport, fights, prizes, recap }

/// Partecipante fotografato dal BE all'avvio della bozza.
class MissionParticipant extends Equatable {
  const MissionParticipant({
    required this.characterId,
    required this.name,
    required this.title,
    required this.maxLifePoints,
    required this.pendingQuestId,
  });

  final String characterId;
  final String name;

  /// `null` per un titolo che il client non conosce.
  final TitleType? title;

  /// Tetto dello slider della vita (regola 4: servito, mai calcolato).
  final int maxLifePoints;
  final String pendingQuestId;

  static MissionParticipant? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final characterId = json['character'];
    final name = json['name'];
    final maxLifePoints = missionIntOf(json['maxLifePoints']);
    final pendingQuestId = json['pendingQuest'];
    if (characterId is! String || name is! String) return null;
    if (maxLifePoints == null || pendingQuestId is! String) return null;
    return MissionParticipant(
      characterId: characterId,
      name: name,
      title: TitleType.values.asNameMap()[json['title']],
      maxLifePoints: maxLifePoints,
      pendingQuestId: pendingQuestId,
    );
  }

  @override
  List<Object?> get props => [
    characterId,
    name,
    title,
    maxLifePoints,
    pendingQuestId,
  ];
}

/// Bozza del flusso guidato servita dal BE (D-09): è lo stato del wizard.
class MissionDraft extends Equatable {
  const MissionDraft({
    required this.id,
    required this.questId,
    this.questType,
    this.step,
    this.placeId,
    this.startedAt,
    this.updatedAt,
    this.participants = const [],
    this.fights = const [],
    this.prizes = const [],
  });

  final String id;
  final String questId;
  final QuestType? questType;

  /// `null` per un passo che il client non conosce (Pitfall 8).
  final MissionDraftStep? step;

  /// Luogo del gruppo; `null` = teletrasporto da fare o saltato (D-01).
  final String? placeId;

  /// UTC.
  final DateTime? startedAt;

  /// UTC.
  final DateTime? updatedAt;
  final List<MissionParticipant> participants;

  /// Anche vuota: storia narrativa con i soli premi (D-24).
  final List<MissionFight> fights;
  final List<MissionPrize> prizes;

  /// Vero anche senza scontri (D-24): letto dal verdetto servito, mai calcolato.
  bool get allFightsSimulated => fights.every((fight) => fight.isSimulated);

  MissionPrize? prizeOf(String characterId) {
    for (final prize in prizes) {
      if (prize.characterId == characterId) return prize;
    }
    return null;
  }

  /// Confine di parsing: senza `id` o `quest` vale `null`; una voce malformata
  /// è scartata e la bozza resta (Pitfall 8).
  static MissionDraft? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final questId = json['quest'];
    if (id is! String || questId is! String) return null;
    final placeId = json['place'];
    return MissionDraft(
      id: id,
      questId: questId,
      questType: QuestType.values.asNameMap()[json['questType']],
      step: MissionDraftStep.values.asNameMap()[json['step']],
      placeId: placeId is String ? placeId : null,
      startedAt: utcInstantOrNull(json['startedAt']),
      updatedAt: utcInstantOrNull(json['updatedAt']),
      participants: missionEntriesOf(
        json['participants'],
        MissionParticipant.tryFromJson,
      ),
      fights: missionEntriesOf(json['fights'], MissionFight.tryFromJson),
      prizes: missionEntriesOf(json['prizes'], MissionPrize.tryFromJson),
    );
  }

  @override
  List<Object?> get props => [
    id,
    questId,
    questType,
    step,
    placeId,
    startedAt,
    updatedAt,
    participants,
    fights,
    prizes,
  ];
}
