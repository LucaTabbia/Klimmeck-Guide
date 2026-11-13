import 'dart:math' show min;

import 'package:equatable/equatable.dart';

import '../enemy.dart';
import '../enums/quest_type.dart';
import '../enums/title_type.dart';
import '../quantity_line.dart';
import '../travel/travel_preview.dart';
import 'adventurer_slot.dart';
import 'quest.dart';
import 'quest_availability.dart';
import 'quest_blocked_reason.dart';
import 'quest_capacity.dart';
import 'quest_cost_line.dart';
import 'quest_enemy.dart';
import 'quest_lane.dart';
import 'quest_travel_line.dart';
import 'quest_viewer.dart';
import 'registered_adventurer.dart';

enum QuestSheetFamily { combat, narrative, service }

/// Famiglia del foglio sulla Bacheca (Phase 6 D-09); la aid è un combattimento (Phase 9 D-17).
QuestSheetFamily questSheetFamilyOf(QuestType? type) => switch (type) {
  QuestType.hunt ||
  QuestType.enemy ||
  QuestType.boss ||
  QuestType.dungeon ||
  QuestType.aid => QuestSheetFamily.combat,
  QuestType.story || QuestType.worldMission => QuestSheetFamily.narrative,
  _ => QuestSheetFamily.service,
};

class QuestSlotLine extends Equatable {
  const QuestSlotLine({
    required this.title,
    required this.registered,
    required this.count,
    required this.isViewerRank,
  });

  final TitleType? title;
  final int registered;
  final int count;
  final bool isViewerRank;

  String get text =>
      '${title?.label ?? 'Qualsiasi rango'}: $registered / $count';

  @override
  List<Object?> get props => [title, registered, count, isViewerRank];
}

/// Cosa mostra il foglio (D-09/D-10): il widget rende solo questo.
class QuestSheetDetails extends Equatable {
  const QuestSheetDetails({
    required this.family,
    required this.requiredTitleText,
    required this.isTitleIneligible,
    required this.slotLines,
    required this.costLine,
    required this.blockedReason,
    this.isImprisoned = false,
    required this.recommendedLootLines,
    required this.loreParagraphs,
    required this.enemyLines,
    required this.strongestEnemy,
    this.isStrongestEnemyKnown = true,
    required this.petPrizeLine,
    required this.travelLine,
  });

  factory QuestSheetDetails.of(
    Quest quest, {
    QuestViewer? viewer,
    TravelPreview? travelPreview,
  }) {
    final type = quest.infos?.type;
    final family = questSheetFamilyOf(type);
    final minTitle = quest.requirements?.minTitle;
    final enemies = quest.infos?.enemies ?? const <QuestEnemy>[];
    final strongest = strongestEntryOf(enemies);
    final availability = viewer == null
        ? null
        : standingOf(quest, viewer).availability;
    return QuestSheetDetails(
      family: family,
      requiredTitleText: _requiredTitleText(type, minTitle),
      isTitleIneligible:
          viewer != null &&
          type != null &&
          !isTitleEligible(type: type, minTitle: minTitle, title: viewer.title),
      slotLines: _drawsSeats(type)
          ? List.unmodifiable(
              _slotLinesOf(
                quest.requirements?.requiredAdventurers ?? const [],
                quest.registeredAdventurers,
                viewer,
              ),
            )
          : const [],
      costLine: costLineOf(quest, viewer?.twitchPoints),
      blockedReason: availability == null
          ? null
          : questBlockedReasonOf(availability, minTitle: minTitle, type: type),
      isImprisoned: availability == QuestAvailability.imprisoned,
      recommendedLootLines: List.unmodifiable([
        for (final entry in quest.requirements?.recommendedLoot ?? const [])
          if (entry.item?.name?.isNotEmpty ?? false)
            quantityLine(entry.quantity ?? 1, entry.item!.name!),
      ]),
      loreParagraphs: List.unmodifiable([
        for (final lore in quest.infos?.relatedLore ?? const [])
          if (lore.description?.isNotEmpty ?? false) lore.description!,
      ]),
      enemyLines: enemyLinesOf(enemies),
      strongestEnemy: strongest?.enemy,
      isStrongestEnemyKnown: strongest?.known ?? true,
      petPrizeLine: _petPrizeLine(quest.prizes?.pet?.name),
      travelLine: family == QuestSheetFamily.narrative
          ? null
          : QuestTravelLine.of(travelPreview),
    );
  }

  final QuestSheetFamily family;
  final String? requiredTitleText;
  final bool isTitleIneligible;
  final List<QuestSlotLine> slotLines;
  final QuestCostLine? costLine;
  final String? blockedReason;

  /// Rifiuto per prigione (quick 261110-cgd): il foglio completa la riga con
  /// il tempo che manca.
  final bool isImprisoned;
  final List<String> recommendedLootLines;
  final List<String> loreParagraphs;

  /// Righe «Nx nome» nell'ordine del BE (D-02); il ritratto usa [strongestEnemy].
  final List<String> enemyLines;
  final Enemy? strongestEnemy;

  /// Il ritratto segue il `known` del più forte (D-08): `false` → sagoma nera.
  final bool isStrongestEnemyKnown;
  final String? petPrizeLine;

  /// Riga «Viaggio» (D-04): mai sulle narrative (story e worldMission non
  /// viaggiano).
  final QuestTravelLine? travelLine;

  @override
  List<Object?> get props => [
    family,
    requiredTitleText,
    isTitleIneligible,
    slotLines,
    costLine,
    blockedReason,
    isImprisoned,
    recommendedLootLines,
    loreParagraphs,
    enemyLines,
    strongestEnemy,
    isStrongestEnemyKnown,
    petPrizeLine,
    travelLine,
  ];
}

/// Una quest a giocatore singolo non disegna posti: resta il titolo minimo.
bool _drawsSeats(QuestType? type) =>
    type != null &&
    registeredQuestTypes.contains(type) &&
    !isSinglePlayerQuest(type);

/// Copy provvisoria (D-06): solo testo, nessuna immagine.
String? _petPrizeLine(String? name) =>
    name == null || name.isEmpty ? null : 'Compagno in premio: $name';

String? _requiredTitleText(QuestType? type, TitleType? minTitle) {
  if (minTitle == null) return null;
  return type == QuestType.story
      ? 'Titolo richiesto: ${minTitle.label}'
      : 'Titolo minimo: ${minTitle.label}';
}

/// Stessa regola di `canRegisterWithTitle`: gli slot esatti si riempiono prima
/// del jolly, l'eccedenza (e i registrati di rango ignoto) occupa il jolly; i
/// legend oltre i posti legend contano sui posti hero (BE 13.1 D-08).
List<QuestSlotLine> _slotLinesOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  QuestViewer? viewer,
) {
  final counts = foldedCountsOf(slots, registered);
  final viewerSeat = _viewerSeatTitleOf(slots, registered, viewer);

  final titles = <TitleType>[];
  for (final slot in slots) {
    final title = slot.title;
    if (title != null && !titles.contains(title)) titles.add(title);
  }
  final anyCount = exactSeatsOf(slots, null);

  return [
    for (final title in titles)
      QuestSlotLine(
        title: title,
        registered: min(counts[title]!, exactSeatsOf(slots, title)),
        count: exactSeatsOf(slots, title),
        isViewerRank: title == viewerSeat,
      ),
    if (anyCount > 0)
      QuestSlotLine(
        title: null,
        registered: min(anyRankOverflowOf(slots, registered), anyCount),
        count: anyCount,
        isViewerRank: false,
      ),
  ];
}

/// Il posto che il viewer occupa o occuperebbe accanto agli altri registrati.
TitleType? _viewerSeatTitleOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  QuestViewer? viewer,
) {
  final title = viewer?.title;
  if (title == null) return null;
  final others = [
    for (final r in registered)
      if (r.characterId != viewer!.characterId) r,
  ];
  return seatTitleOf(slots, others, title);
}
