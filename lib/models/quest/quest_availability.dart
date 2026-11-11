import 'package:equatable/equatable.dart';

import '../enums/quest_type.dart';
import '../enums/title_type.dart';
import 'quest.dart';
import 'quest_capacity.dart';
import 'quest_lane.dart';
import 'quest_viewer.dart';

/// Perché una quest non è accettabile secondo il client; l'ordine rispecchia il BE
/// (handoff Phase 7 §2). Il backend resta il giudice: questo stato blocca solo lo swipe.
enum QuestAvailability {
  available,
  tornForOwner,
  notAcceptable,
  alreadyDone,
  titleMismatch,
  laneBusy,
  full,
  notInCity,
  insufficientPoints,

  /// Il backend dice che la quest non avrebbe effetto (D-20): foglio strappato.
  noEffect,

  /// Il personaggio è in prigione (quick 261110-cgd): nessuna quest.
  imprisoned,
}

class QuestStanding extends Equatable {
  const QuestStanding({required this.availability, required this.isTorn});

  final QuestAvailability availability;

  /// Foglio strappato sulla board: vedi [isSheetTorn].
  final bool isTorn;

  bool get canAccept => availability == QuestAvailability.available;

  @override
  List<Object?> get props => [availability, isTorn];
}

bool isTitleEligible({
  required QuestType type,
  required TitleType? minTitle,
  required TitleType? title,
}) {
  if (minTitle == null) return true;
  if (title == null) return false;
  return type == QuestType.story
      ? title == minTitle
      : title.index >= minTitle.index;
}

QuestStanding standingOf(Quest quest, QuestViewer viewer) {
  final availability = _availabilityOf(quest, viewer);
  return QuestStanding(
    availability: availability,
    isTorn: isSheetTorn(
      availability,
      failsOwnRequirements: _failsOwnRequirements(quest, viewer),
    ),
  );
}

/// Ogni quest non accettabile ha il foglio strappato (quick 261110-mag); la sola
/// corsia occupata lo lascia intero, a meno che fallisca un requisito della
/// quest stessa (posto, effetto, punti).
bool isSheetTorn(
  QuestAvailability availability, {
  required bool failsOwnRequirements,
}) => switch (availability) {
  QuestAvailability.available => false,
  QuestAvailability.laneBusy => failsOwnRequirements,
  QuestAvailability.tornForOwner ||
  QuestAvailability.notAcceptable ||
  QuestAvailability.alreadyDone ||
  QuestAvailability.titleMismatch ||
  QuestAvailability.full ||
  QuestAvailability.notInCity ||
  QuestAvailability.insufficientPoints ||
  QuestAvailability.noEffect ||
  QuestAvailability.imprisoned => true,
};

/// Requisiti della quest indipendenti dalla corsia, letti anche a corsia occupata.
bool _failsOwnRequirements(Quest quest, QuestViewer viewer) =>
    quest.noEffect ||
    _isFullForViewer(quest, viewer) ||
    _lacksPoints(quest, viewer);

QuestAvailability _availabilityOf(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  if (type == null) return QuestAvailability.notAcceptable;
  final lane = laneOf(type);
  final requirements = quest.requirements;

  if (laneQuestOf(viewer.quests, lane)?.quest?.id == quest.id) {
    return QuestAvailability.tornForOwner;
  }
  if (viewer.imprisonedFor != null) return QuestAvailability.imprisoned;
  if (_isCatalogueDefect(type, lane, quest)) {
    return QuestAvailability.notAcceptable;
  }
  if (nonRepeatableQuestTypes.contains(type) && _isDone(quest, type, viewer)) {
    return QuestAvailability.alreadyDone;
  }
  if (!isTitleEligible(
    type: type,
    minTitle: requirements?.minTitle,
    title: viewer.title,
  )) {
    return QuestAvailability.titleMismatch;
  }
  if (laneQuestOf(viewer.quests, lane) != null) {
    return QuestAvailability.laneBusy;
  }
  if (_isFullForViewer(quest, viewer)) return QuestAvailability.full;
  if (lane != QuestLane.story &&
      !(viewer.cityPointIds?.contains(quest.infos?.markerLocation?.id) ??
          false)) {
    return QuestAvailability.notInCity;
  }
  if (_lacksPoints(quest, viewer)) return QuestAvailability.insufficientPoints;
  return quest.noEffect
      ? QuestAvailability.noEffect
      : QuestAvailability.available;
}

/// Con la forma Phase 7 (`Int`) una capienza 0 non è un difetto: decide il BE.
bool _isCatalogueDefect(QuestType type, QuestLane lane, Quest quest) {
  final requirements = quest.requirements;
  if (lane != QuestLane.standard && (requirements?.requiredPoints ?? 0) <= 0) {
    return true;
  }
  return registeredQuestTypes.contains(type) &&
      (requirements?.requiredAdventurers.isEmpty ?? true) &&
      (requirements?.hasRankSlots ?? false);
}

bool _isDone(Quest quest, QuestType type, QuestViewer viewer) {
  final completed = viewer.quests?.completedQuests ?? const [];
  if (completed.any((done) => done.id == quest.id)) return true;
  return registeredQuestTypes.contains(type) &&
      quest.registeredAdventurers.any(
        (registered) => registered.characterId == viewer.characterId,
      );
}

/// La corsia standard non paga punti (BE Phase 7); un saldo ignoto non blocca.
bool _lacksPoints(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  final balance = viewer.twitchPoints;
  if (type == null || balance == null) return false;
  return laneOf(type) != QuestLane.standard &&
      balance < (quest.requirements?.requiredPoints ?? 0);
}

bool _isFullForViewer(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  if (type == null || !registeredQuestTypes.contains(type)) return false;
  return isFullFor(
    questSlotsOf(type, quest.requirements?.requiredAdventurers ?? const []),
    quest.registeredAdventurers,
    viewer.title,
  );
}
