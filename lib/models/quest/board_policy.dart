import '../city.dart';
import '../enums/quest_type.dart';
import '../point_of_interest.dart';
import 'quest.dart';
import 'quest_lane.dart';
import 'quest_viewer.dart';

/// Città il cui marker coincide con la posizione del personaggio (D-11): la board
/// è raggiungibile solo da qui.
City? currentCityOf(List<City> cities, PointOfInterest? location) {
  if (location == null) return null;
  for (final city in cities) {
    if (city.markerLocation?.id == location.id) return city;
  }
  return null;
}

bool isOnCityMarker(List<City> cities, PointOfInterest? location) =>
    currentCityOf(cities, location) != null;

/// Quest mostrate sulla board (D-11/D-12): quelle della città, worldMission incluse,
/// la sola story del titolo esatto da ogni città, la propria story/worldMission attiva
/// (strappata).
List<Quest> boardQuestsFor(List<Quest> quests, QuestViewer viewer) =>
    List.unmodifiable(quests.where((quest) => _isListed(quest, viewer)));

bool _isListed(Quest quest, QuestViewer viewer) {
  final type = quest.infos?.type;
  if (type == null) return false;
  if (laneQuestOf(viewer.quests, laneOf(type))?.quest?.id == quest.id) {
    return true;
  }
  if (nonRepeatableQuestTypes.contains(type) && _isCompleted(quest, viewer)) {
    return false;
  }
  return switch (type) {
    QuestType.story => quest.requirements?.minTitle == viewer.title,
    _ =>
      viewer.cityPointIds?.contains(quest.infos?.markerLocation?.id) ?? false,
  };
}

bool _isCompleted(Quest quest, QuestViewer viewer) =>
    (viewer.quests?.completedQuests ?? const []).any(
      (done) => done.id == quest.id,
    );
