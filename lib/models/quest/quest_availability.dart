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
}

class QuestStanding extends Equatable {
  const QuestStanding({required this.availability, required this.isTorn});

  final QuestAvailability availability;

  /// Foglio strappato sulla board: corsia del proprietario o posti esauriti (D-12).
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
    isTorn:
        availability == QuestAvailability.tornForOwner ||
        _isFullForViewer(quest, viewer),
  );
}

QuestAvailability _availabilityOf(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  if (type == null) return QuestAvailability.notAcceptable;
  final lane = laneOf(type);
  final requirements = quest.requirements;

  if (laneQuestOf(viewer.quests, lane)?.quest?.id == quest.id) {
    return QuestAvailability.tornForOwner;
  }
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
  final balance = viewer.twitchPoints;
  if (lane != QuestLane.standard &&
      balance != null &&
      balance < (requirements?.requiredPoints ?? 0)) {
    return QuestAvailability.insufficientPoints;
  }
  return QuestAvailability.available;
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

bool _isFullForViewer(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  if (type == null || !registeredQuestTypes.contains(type)) return false;
  return isFullFor(
    quest.requirements?.requiredAdventurers ?? const [],
    quest.registeredAdventurers,
    viewer.title,
  );
}
