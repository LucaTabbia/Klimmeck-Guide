import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

PointOfInterest poi(String id) => PointOfInterest.fromJson({
  'id': id,
  'location': [1.0, 2.0],
});

City city(String id, String markerId) => City.fromJson({
  'id': id,
  'markerLocation': {
    'id': markerId,
    'location': [1.0, 2.0],
  },
});

void main() {
  group('currentCityOf', () {
    final cities = [city('city-1', 'marker-1'), city('city-2', 'marker-2')];

    test('returns the city whose marker is the location', () {
      expect(currentCityOf(cities, poi('marker-2'))?.id, 'city-2');
    });

    test('a quest POI that is not a marker gives null', () {
      expect(currentCityOf(cities, poi('poi-1')), isNull);
    });

    test('null location gives null', () {
      expect(currentCityOf(cities, null), isNull);
    });
  });

  group('boardQuestsFor', () {
    const standardTypes = [
      'hunt',
      'job',
      'heal',
      'dungeon',
      'enemy',
      'boss',
      'aid',
      'study',
      'crime',
      'guard',
    ];

    List<String> ids(List<Quest> quests) => quests.map((q) => q.id).toList();

    test('lists city quests of every standard type, hides the others', () {
      final inCity = [
        for (final t in standardTypes) buildQuest(id: 'in-$t', type: t),
      ];
      final outside = [
        for (final t in standardTypes)
          buildQuest(id: 'out-$t', type: t, markerId: 'poi-9'),
      ];
      final listed = boardQuestsFor([...inCity, ...outside], buildViewer());
      expect(ids(listed), ids(inCity));
    });

    test('without a known city no standard quest is listed', () {
      final quests = [for (final t in standardTypes) buildQuest(type: t)];
      expect(boardQuestsFor(quests, buildViewer(cityPointIds: null)), isEmpty);
    });

    test('worldMission is listed only in its own city', () {
      final own = buildQuest(
        id: 'wm-own',
        type: 'worldMission',
        requiredPoints: 100,
      );
      final other = buildQuest(
        id: 'wm-other',
        type: 'worldMission',
        requiredPoints: 100,
        markerId: 'poi-9',
      );
      expect(ids(boardQuestsFor([own, other], buildViewer())), ['wm-own']);
      expect(boardQuestsFor([own], buildViewer(cityPointIds: null)), isEmpty);
      final owner = buildViewer(
        quests: buildLanes(
          activeWorldMissionQuest: laneJson(questId: 'wm-other'),
        ),
      );
      expect(ids(boardQuestsFor([own, other], owner)), ['wm-own', 'wm-other']);
    });

    test('the story of the exact title is listed from any city', () {
      final story = buildQuest(
        type: 'story',
        requiredPoints: 100,
        markerId: 'poi-9',
      );
      expect(boardQuestsFor([story], buildViewer()), [story]);
    });

    test('only the story of the exact title is listed', () {
      final chapters = [
        for (final t in ['rookie', 'adventurer', 'paladin', 'mage', 'hero'])
          buildQuest(id: 's-$t', type: 'story', minTitle: t, requiredPoints: 1),
      ];
      final listed = boardQuestsFor(
        chapters,
        buildViewer(title: TitleType.paladin),
      );
      expect(ids(listed), ['s-paladin']);
    });

    test('completed non-repeatable hidden, completed repeatable listed', () {
      final enemy = buildQuest(id: 'e', type: 'enemy');
      final hunt = buildQuest(id: 'h', type: 'hunt');
      final viewer = buildViewer(
        quests: buildLanes(completedQuestIds: ['e', 'h']),
      );
      expect(ids(boardQuestsFor([enemy, hunt], viewer)), ['h']);
    });

    test('the owner keeps the active story listed even if completed', () {
      final story = buildQuest(
        id: 's-old',
        type: 'story',
        minTitle: 'rookie',
        requiredPoints: 1,
      );
      final viewer = buildViewer(
        title: TitleType.paladin,
        quests: buildLanes(
          activeStoryQuest: laneJson(questId: 's-old'),
          completedQuestIds: ['s-old'],
        ),
      );
      expect(boardQuestsFor([story], viewer), [story]);
    });

    test('quests without a type are not listed', () {
      final quest = Quest.fromJson({'id': 'q-x'});
      expect(boardQuestsFor([quest], buildViewer()), isEmpty);
    });

    test('preserves the input order', () {
      final quests = [
        buildQuest(id: 'b', type: 'hunt'),
        buildQuest(id: 'a', type: 'job'),
        buildQuest(id: 'c', type: 'heal'),
      ];
      expect(ids(boardQuestsFor(quests, buildViewer())), ['b', 'a', 'c']);
    });
  });

  group('needsTravelPreview', () {
    test('asks for an acceptable standard quest (D-04)', () {
      expect(
        needsTravelPreview(buildQuest(type: 'hunt'), buildViewer()),
        isTrue,
      );
    });

    test('skips an acceptable story or worldMission (D-04)', () {
      final story = buildQuest(type: 'story', requiredPoints: 100);
      final worldMission = buildQuest(
        type: 'worldMission',
        requiredPoints: 100,
      );
      final viewer = buildViewer();
      expect(standingOf(story, viewer).canAccept, isTrue);
      expect(standingOf(worldMission, viewer).canAccept, isTrue);
      expect(needsTravelPreview(story, viewer), isFalse);
      expect(needsTravelPreview(worldMission, viewer), isFalse);
    });

    test('skips a quest the viewer cannot accept (D-04)', () {
      final busy = buildViewer(
        quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
      );
      final mismatch = buildViewer(title: TitleType.rookie);
      expect(needsTravelPreview(buildQuest(type: 'hunt'), busy), isFalse);
      expect(
        needsTravelPreview(
          buildQuest(type: 'hunt', minTitle: 'hero'),
          mismatch,
        ),
        isFalse,
      );
    });
  });
}
