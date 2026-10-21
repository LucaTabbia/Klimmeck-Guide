import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/character_quests.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  test('fromJson parses the three lanes', () {
    final quests = CharacterQuests.fromJson({
      'completedQuests': [],
      'pendingQuest': laneJson(id: 'pq-a', questId: 'q-a'),
      'activeStoryQuest': laneJson(id: 'pq-s', questId: 'q-s'),
      'activeWorldMissionQuest': laneJson(id: 'pq-w', questId: 'q-w'),
    });
    expect(quests.pendingQuest!.id, 'pq-a');
    expect(quests.activeStoryQuest!.quest!.id, 'q-s');
    expect(quests.activeWorldMissionQuest!.quest!.id, 'q-w');
  });

  test('missing or null lanes parse to null with no completed quests', () {
    final quests = CharacterQuests.fromJson({'activeStoryQuest': null});
    expect(quests.pendingQuest, isNull);
    expect(quests.activeStoryQuest, isNull);
    expect(quests.activeWorldMissionQuest, isNull);
    expect(quests.completedQuests, isEmpty);
  });

  test('toJson emits the three lane ids', () {
    final json = CharacterQuests.fromJson({
      'pendingQuest': laneJson(id: 'pq-a'),
      'activeStoryQuest': laneJson(id: 'pq-s'),
      'activeWorldMissionQuest': laneJson(id: 'pq-w'),
    }).toJson();
    expect(json['pendingQuest'], 'pq-a');
    expect(json['activeStoryQuest'], 'pq-s');
    expect(json['activeWorldMissionQuest'], 'pq-w');
  });

  test('Character.fromJson exposes the story lane quest id', () {
    final character = Character.fromJson(
      characterWithLanesJson(
        activeStoryQuest: laneJson(id: 'pq-s', questId: 'q-story'),
      ),
    );
    expect(character.quests!.activeStoryQuest!.quest!.id, 'q-story');
  });
}
