import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  QuestAvailability availabilityOf(Quest quest, viewer) =>
      standingOf(quest, viewer).availability;

  group('standingOf', () {
    test('available quest can be accepted and is not torn', () {
      final standing = standingOf(buildQuest(type: 'hunt'), buildViewer());
      expect(standing.availability, QuestAvailability.available);
      expect(standing.canAccept, isTrue);
      expect(standing.isTorn, isFalse);
    });

    test('lane holding this quest is torn for the owner', () {
      final viewer = buildViewer(
        quests: buildLanes(activeStoryQuest: laneJson(questId: 'q-1')),
      );
      final standing = standingOf(
        buildQuest(type: 'story', requiredPoints: 3000),
        viewer,
      );
      expect(standing.availability, QuestAvailability.tornForOwner);
      expect(standing.isTorn, isTrue);
      expect(standing.canAccept, isFalse);
    });

    test('story without requiredPoints is a catalogue defect', () {
      expect(
        availabilityOf(buildQuest(type: 'story'), buildViewer()),
        QuestAvailability.notAcceptable,
      );
      expect(
        availabilityOf(
          buildQuest(type: 'story', requiredPoints: 0),
          buildViewer(),
        ),
        QuestAvailability.notAcceptable,
      );
    });

    test('boss with an empty slot list (Phase 8 shape) is not acceptable', () {
      expect(
        availabilityOf(buildQuest(type: 'boss', slots: []), buildViewer()),
        QuestAvailability.notAcceptable,
      );
    });

    test('quest without a type is not acceptable', () {
      final quest = Quest.fromJson({'id': 'q-x'});
      expect(
        availabilityOf(quest, buildViewer()),
        QuestAvailability.notAcceptable,
      );
    });

    for (final type in ['boss', 'enemy', 'aid']) {
      test('legacy-0 $type imposes no client constraint', () {
        final quest = Quest.fromJson(
          legacyQuestJson(type: type, requiredAdventurers: 0, registered: []),
        );
        final standing = standingOf(quest, buildViewer());
        expect(standing.availability, QuestAvailability.available);
        expect(standing.isTorn, isFalse);
      });
    }

    test('completed non-repeatable enemy is already done', () {
      final viewer = buildViewer(
        quests: buildLanes(completedQuestIds: ['q-1']),
      );
      expect(
        availabilityOf(buildQuest(type: 'enemy'), viewer),
        QuestAvailability.alreadyDone,
      );
    });

    test('boss with the viewer registered is already done', () {
      expect(
        availabilityOf(
          buildQuest(type: 'boss', registered: ['c-1']),
          buildViewer(),
        ),
        QuestAvailability.alreadyDone,
      );
    });

    test('completed hunt is repeatable', () {
      final viewer = buildViewer(
        quests: buildLanes(completedQuestIds: ['q-1']),
      );
      expect(
        availabilityOf(buildQuest(type: 'hunt'), viewer),
        QuestAvailability.available,
      );
    });

    test('story needs the exact title', () {
      final quest = buildQuest(
        type: 'story',
        minTitle: 'paladin',
        requiredPoints: 100,
      );
      expect(
        availabilityOf(quest, buildViewer(title: TitleType.mage)),
        QuestAvailability.titleMismatch,
      );
      expect(
        availabilityOf(quest, buildViewer(title: TitleType.paladin)),
        QuestAvailability.available,
      );
    });

    test('other types need at least the minimum title', () {
      final quest = buildQuest(type: 'enemy', minTitle: 'paladin');
      expect(
        availabilityOf(quest, buildViewer(title: TitleType.mage)),
        QuestAvailability.available,
      );
      expect(
        availabilityOf(quest, buildViewer(title: TitleType.adventurer)),
        QuestAvailability.titleMismatch,
      );
    });

    test('no minTitle means no title constraint', () {
      expect(
        availabilityOf(
          buildQuest(type: 'hunt', minTitle: null),
          buildViewer(title: null),
        ),
        QuestAvailability.available,
      );
    });

    test('standard lane busy blocks a hunt but not a story', () {
      final viewer = buildViewer(
        quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
      );
      expect(
        availabilityOf(buildQuest(type: 'hunt'), viewer),
        QuestAvailability.laneBusy,
      );
      expect(
        availabilityOf(buildQuest(type: 'story', requiredPoints: 10), viewer),
        QuestAvailability.available,
      );
    });

    test('D-32 canonical: rank slots decide fullness per title', () {
      final quest = buildQuest(
        type: 'boss',
        slots: [
          {'title': 'hero', 'count': 1},
          {'title': null, 'count': 2},
        ],
        registered: [
          {'character': 'c-2', 'title': 'paladin'},
          {'character': 'c-3', 'title': 'mage'},
        ],
      );
      final paladin = standingOf(quest, buildViewer(title: TitleType.paladin));
      expect(paladin.availability, QuestAvailability.full);
      expect(paladin.isTorn, isTrue);
      expect(
        availabilityOf(quest, buildViewer(title: TitleType.hero)),
        QuestAvailability.available,
      );
    });

    test('full worldMission with a busy lane is laneBusy and still torn', () {
      final quest = buildQuest(
        type: 'worldMission',
        requiredPoints: 100,
        slots: [
          {'title': null, 'count': 1},
        ],
        registered: [
          {'character': 'c-2', 'title': 'paladin'},
        ],
      );
      final viewer = buildViewer(
        quests: buildLanes(activeWorldMissionQuest: laneJson(questId: 'other')),
      );
      final standing = standingOf(quest, viewer);
      expect(standing.availability, QuestAvailability.laneBusy);
      expect(standing.isTorn, isTrue);
    });

    test('standard quest outside the city is notInCity', () {
      final quest = buildQuest(type: 'hunt', markerId: 'poi-9');
      expect(availabilityOf(quest, buildViewer()), QuestAvailability.notInCity);
      expect(
        availabilityOf(
          buildQuest(type: 'hunt'),
          buildViewer(cityPointIds: null),
        ),
        QuestAvailability.notInCity,
      );
    });

    test(
      'worldMission outside its city is notInCity; story ignores the city',
      () {
        QuestAvailability worldMissionAt(
          String markerId, {
          Set<String>? city,
        }) => availabilityOf(
          buildQuest(
            type: 'worldMission',
            requiredPoints: 100,
            markerId: markerId,
          ),
          buildViewer(cityPointIds: city),
        );
        expect(
          worldMissionAt('poi-9', city: {'poi-1'}),
          QuestAvailability.notInCity,
        );
        expect(
          worldMissionAt('poi-1', city: {'poi-1'}),
          QuestAvailability.available,
        );
        expect(worldMissionAt('poi-1'), QuestAvailability.notInCity);
        final story = buildQuest(
          type: 'story',
          requiredPoints: 100,
          markerId: 'poi-9',
        );
        expect(
          availabilityOf(story, buildViewer()),
          QuestAvailability.available,
        );
        expect(
          availabilityOf(story, buildViewer(cityPointIds: null)),
          QuestAvailability.available,
        );
      },
    );

    test('insufficient points only for story and worldMission', () {
      final quest = buildQuest(type: 'story', requiredPoints: 3000);
      expect(
        availabilityOf(quest, buildViewer(twitchPoints: 1200)),
        QuestAvailability.insufficientPoints,
      );
      expect(
        availabilityOf(quest, buildViewer(twitchPoints: null)),
        QuestAvailability.available,
      );
    });

    test('order: completed wins over title mismatch', () {
      final viewer = buildViewer(
        title: TitleType.rookie,
        quests: buildLanes(completedQuestIds: ['q-1']),
      );
      expect(
        availabilityOf(buildQuest(type: 'enemy', minTitle: 'hero'), viewer),
        QuestAvailability.alreadyDone,
      );
    });
  });

  group('isTitleEligible', () {
    test('story requires the exact title', () {
      expect(
        isTitleEligible(
          type: QuestType.story,
          minTitle: TitleType.hero,
          title: TitleType.legend,
        ),
        isFalse,
      );
    });

    test('other types accept higher titles', () {
      expect(
        isTitleEligible(
          type: QuestType.boss,
          minTitle: TitleType.hero,
          title: TitleType.legend,
        ),
        isTrue,
      );
    });

    test('unknown title with a minimum is not eligible', () {
      expect(
        isTitleEligible(
          type: QuestType.boss,
          minTitle: TitleType.hero,
          title: null,
        ),
        isFalse,
      );
    });
  });
}
