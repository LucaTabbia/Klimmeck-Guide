import 'dart:math' show max, min;

import 'package:equatable/equatable.dart';

import '../enums/quest_type.dart';
import '../enums/title_type.dart';
import 'adventurer_slot.dart';
import 'quest.dart';
import 'quest_availability.dart';
import 'quest_blocked_reason.dart';
import 'quest_cost_line.dart';
import 'quest_lane.dart';
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
    required this.recommendedLootLines,
    required this.loreParagraphs,
  });

  factory QuestSheetDetails.of(Quest quest, {QuestViewer? viewer}) {
    final type = quest.infos?.type;
    final minTitle = quest.requirements?.minTitle;
    return QuestSheetDetails(
      family: questSheetFamilyOf(type),
      requiredTitleText: _requiredTitleText(type, minTitle),
      isTitleIneligible:
          viewer != null &&
          type != null &&
          !isTitleEligible(type: type, minTitle: minTitle, title: viewer.title),
      slotLines: type != null && registeredQuestTypes.contains(type)
          ? List.unmodifiable(
              _slotLinesOf(
                quest.requirements?.requiredAdventurers ?? const [],
                quest.registeredAdventurers,
                viewer?.title,
              ),
            )
          : const [],
      costLine: costLineOf(quest, viewer?.twitchPoints),
      blockedReason: viewer == null
          ? null
          : questBlockedReasonOf(
              standingOf(quest, viewer).availability,
              minTitle: minTitle,
              type: type,
            ),
      recommendedLootLines: List.unmodifiable([
        for (final entry in quest.requirements?.recommendedLoot ?? const [])
          if (entry.item?.name?.isNotEmpty ?? false)
            '${entry.quantity ?? 1}x ${entry.item!.name}',
      ]),
      loreParagraphs: List.unmodifiable([
        for (final lore in quest.infos?.relatedLore ?? const [])
          if (lore.description?.isNotEmpty ?? false) lore.description!,
      ]),
    );
  }

  final QuestSheetFamily family;
  final String? requiredTitleText;
  final bool isTitleIneligible;
  final List<QuestSlotLine> slotLines;
  final QuestCostLine? costLine;
  final String? blockedReason;
  final List<String> recommendedLootLines;
  final List<String> loreParagraphs;

  @override
  List<Object?> get props => [
    family,
    requiredTitleText,
    isTitleIneligible,
    slotLines,
    costLine,
    blockedReason,
    recommendedLootLines,
    loreParagraphs,
  ];
}

String? _requiredTitleText(QuestType? type, TitleType? minTitle) {
  if (minTitle == null) return null;
  return type == QuestType.story
      ? 'Titolo richiesto: ${minTitle.label}'
      : 'Titolo minimo: ${minTitle.label}';
}

/// Stessa regola di `canRegisterWithTitle`: gli slot esatti si riempiono prima
/// del jolly, l'eccedenza (e i registrati di rango ignoto) occupa il jolly.
List<QuestSlotLine> _slotLinesOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  TitleType? viewerTitle,
) {
  int exact(TitleType? t) =>
      slots.where((s) => s.title == t).fold(0, (sum, s) => sum + s.count);
  int reg(TitleType t) => registered.where((r) => r.title == t).length;

  final titles = <TitleType>[];
  for (final slot in slots) {
    final title = slot.title;
    if (title != null && !titles.contains(title)) titles.add(title);
  }
  final anyCount = exact(null);
  final overflow = TitleType.values.fold(
    registered.where((r) => r.title == null).length,
    (sum, t) => sum + max(0, reg(t) - exact(t)),
  );

  return [
    for (final title in titles)
      QuestSlotLine(
        title: title,
        registered: min(reg(title), exact(title)),
        count: exact(title),
        isViewerRank: title == viewerTitle,
      ),
    if (anyCount > 0)
      QuestSlotLine(
        title: null,
        registered: min(overflow, anyCount),
        count: anyCount,
        isViewerRank: false,
      ),
  ];
}
