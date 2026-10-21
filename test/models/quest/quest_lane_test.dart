import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest_lane.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('laneOf', () {
    test('story and worldMission have their own lane', () {
      expect(laneOf(QuestType.story), QuestLane.story);
      expect(laneOf(QuestType.worldMission), QuestLane.worldMission);
    });

    test('every other type is standard', () {
      final others = QuestType.values.where(
        (t) => t != QuestType.story && t != QuestType.worldMission,
      );
      expect(others, hasLength(10));
      for (final type in others) {
        expect(laneOf(type), QuestLane.standard, reason: type.name);
      }
    });
  });

  test('registered and non-repeatable type sets match the backend', () {
    expect(registeredQuestTypes, {
      QuestType.worldMission,
      QuestType.boss,
      QuestType.enemy,
      QuestType.aid,
    });
    expect(nonRepeatableQuestTypes, {
      QuestType.story,
      QuestType.worldMission,
      QuestType.enemy,
      QuestType.boss,
      QuestType.aid,
    });
  });

  group('laneQuestOf', () {
    final lanes = buildLanes(
      pendingQuest: laneJson(id: 'p'),
      activeStoryQuest: laneJson(id: 's'),
      activeWorldMissionQuest: laneJson(id: 'w'),
    );

    test('returns the quest held by each lane', () {
      expect(laneQuestOf(lanes, QuestLane.standard)?.id, 'p');
      expect(laneQuestOf(lanes, QuestLane.story)?.id, 's');
      expect(laneQuestOf(lanes, QuestLane.worldMission)?.id, 'w');
    });

    test('null quests give null', () {
      expect(laneQuestOf(null, QuestLane.story), isNull);
    });
  });

  test('QuestViewer.of reads the character', () {
    final viewer = QuestViewer.of(
      character: Character.fromJson(characterWithLanesJson(title: 'paladin')),
      twitchPoints: 500,
      cityPointIds: {'poi-1'},
    );
    expect(viewer.characterId, 'c-1');
    expect(viewer.title, TitleType.paladin);
    expect(viewer.twitchPoints, 500);
    expect(viewer.cityPointIds, {'poi-1'});
  });
}
