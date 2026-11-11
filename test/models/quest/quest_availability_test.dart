import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';
import 'package:klimmeck_guide/models/quest/quest_lane.dart';

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

    test('magic is a repeatable standard-lane quest (quick 261110-mag)', () {
      expect(laneOf(QuestType.magic), QuestLane.standard);
      expect(nonRepeatableQuestTypes, isNot(contains(QuestType.magic)));
      expect(registeredQuestTypes, isNot(contains(QuestType.magic)));
      final viewer = buildViewer(
        quests: buildLanes(completedQuestIds: ['q-1']),
      );
      expect(
        availabilityOf(buildQuest(type: 'magic'), viewer),
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

    test('a legend takes the hero seat of a boss (BE 13.1 D-08)', () {
      const heroSeat = [
        {'title': 'hero', 'count': 1},
      ];
      final open = buildQuest(type: 'boss', minTitle: 'hero', slots: heroSeat);
      expect(
        availabilityOf(open, buildViewer(title: TitleType.legend)),
        QuestAvailability.available,
      );
      final taken = buildQuest(
        type: 'boss',
        minTitle: 'hero',
        slots: heroSeat,
        registered: [
          {'character': 'c-2', 'title': 'legend'},
        ],
      );
      expect(
        availabilityOf(taken, buildViewer(title: TitleType.hero)),
        QuestAvailability.full,
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

  group('prison (quick 261110-cgd)', () {
    const nineHours = Duration(hours: 9);

    test('an imprisoned viewer cannot accept and every sheet is torn '
        '(quick 261110-cgd)', () {
      for (final type in ['hunt', 'crime', 'study', 'heal']) {
        final standing = standingOf(
          buildQuest(type: type),
          buildViewer(imprisonedFor: nineHours),
        );

        expect(
          standing.availability,
          QuestAvailability.imprisoned,
          reason: type,
        );
        expect(standing.canAccept, isFalse, reason: type);
        expect(standing.isTorn, isTrue, reason: type);
      }
    });

    test('prison comes before a busy lane or a missing requirement '
        '(quick 261110-cgd)', () {
      final viewer = buildViewer(
        imprisonedFor: nineHours,
        title: TitleType.rookie,
        twitchPoints: 0,
        quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
      );

      expect(
        availabilityOf(buildQuest(type: 'hunt'), viewer),
        QuestAvailability.imprisoned,
      );
      expect(
        availabilityOf(buildQuest(type: 'guard', minTitle: 'paladin'), viewer),
        QuestAvailability.imprisoned,
      );
    });

    test('the own lane quest stays the owner\'s (quick 261110-cgd)', () {
      final viewer = buildViewer(
        imprisonedFor: nineHours,
        quests: buildLanes(activeStoryQuest: laneJson(questId: 'q-1')),
      );

      expect(
        availabilityOf(buildQuest(type: 'story', requiredPoints: 3000), viewer),
        QuestAvailability.tornForOwner,
      );
    });

    test('a free viewer is unaffected (quick 261110-cgd)', () {
      expect(
        availabilityOf(buildQuest(type: 'hunt'), buildViewer()),
        QuestAvailability.available,
      );
    });
  });

  group('torn sheet rule (quick 261110-mag)', () {
    // (torn with its own requirements met, torn with one of them failing)
    const expected = {
      QuestAvailability.available: (false, false),
      QuestAvailability.tornForOwner: (true, true),
      QuestAvailability.notAcceptable: (true, true),
      QuestAvailability.alreadyDone: (true, true),
      QuestAvailability.titleMismatch: (true, true),
      QuestAvailability.laneBusy: (false, true),
      QuestAvailability.full: (true, true),
      QuestAvailability.notInCity: (true, true),
      QuestAvailability.insufficientPoints: (true, true),
      QuestAvailability.noEffect: (true, true),
      QuestAvailability.imprisoned: (true, true),
    };

    test('every availability has a torn decision (quick 261110-mag)', () {
      expect(expected.keys.toSet(), QuestAvailability.values.toSet());
      expected.forEach((availability, torn) {
        expect(
          isSheetTorn(availability, failsOwnRequirements: false),
          torn.$1,
          reason: '${availability.name} with its requirements met',
        );
        expect(
          isSheetTorn(availability, failsOwnRequirements: true),
          torn.$2,
          reason: '${availability.name} with a requirement failing',
        );
      });
    });

    test('a quest above the viewer title is torn (quick 261110-mag)', () {
      final standing = standingOf(
        buildQuest(type: 'magic', minTitle: 'mage'),
        buildViewer(title: TitleType.paladin),
      );
      expect(standing.availability, QuestAvailability.titleMismatch);
      expect(standing.isTorn, isTrue);
    });

    test('the same quest is whole once the title is reached '
        '(quick 261110-mag)', () {
      final standing = standingOf(
        buildQuest(type: 'magic', minTitle: 'mage'),
        buildViewer(title: TitleType.mage),
      );
      expect(standing.availability, QuestAvailability.available);
      expect(standing.isTorn, isFalse);
    });

    test('every other refusal is torn (quick 261110-mag)', () {
      final done = standingOf(
        buildQuest(type: 'boss', registered: ['c-1']),
        buildViewer(),
      );
      final defect = standingOf(buildQuest(type: 'story'), buildViewer());
      final away = standingOf(
        buildQuest(type: 'hunt', markerId: 'poi-9'),
        buildViewer(),
      );
      final poor = standingOf(
        buildQuest(type: 'story', requiredPoints: 3000),
        buildViewer(twitchPoints: 1200),
      );
      expect(done.availability, QuestAvailability.alreadyDone);
      expect(defect.availability, QuestAvailability.notAcceptable);
      expect(away.availability, QuestAvailability.notInCity);
      expect(poor.availability, QuestAvailability.insufficientPoints);
      for (final standing in [done, defect, away, poor]) {
        expect(standing.isTorn, isTrue, reason: '${standing.availability}');
      }
    });

    test('a busy lane alone leaves the sheet whole (quick 261110-mag)', () {
      final viewer = buildViewer(
        quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
      );
      final standing = standingOf(buildQuest(type: 'magic'), viewer);
      expect(standing.availability, QuestAvailability.laneBusy);
      expect(standing.isTorn, isFalse);
    });

    test('a busy lane with too few points for the quest is torn '
        '(quick 261110-mag)', () {
      final quest = buildQuest(type: 'worldMission', requiredPoints: 3000);
      final viewer = buildViewer(
        twitchPoints: 1200,
        quests: buildLanes(activeWorldMissionQuest: laneJson(questId: 'other')),
      );
      final standing = standingOf(quest, viewer);
      expect(standing.availability, QuestAvailability.laneBusy);
      expect(standing.isTorn, isTrue);
      expect(
        standingOf(
          quest,
          buildViewer(
            twitchPoints: 5000,
            quests: buildLanes(
              activeWorldMissionQuest: laneJson(questId: 'other'),
            ),
          ),
        ).isTorn,
        isFalse,
      );
    });
  });

  group('noEffect (D-20)', () {
    test('a quest with noEffect is torn and cannot be accepted (D-20)', () {
      final standing = standingOf(
        buildQuest(type: 'heal', noEffect: true),
        buildViewer(),
      );
      expect(standing.availability, QuestAvailability.noEffect);
      expect(standing.isTorn, isTrue);
      expect(standing.canAccept, isFalse);
    });

    test('without the flag the same heal is available and whole (D-20)', () {
      final standing = standingOf(buildQuest(type: 'heal'), buildViewer());
      expect(standing.availability, QuestAvailability.available);
      expect(standing.isTorn, isFalse);
      expect(standing.canAccept, isTrue);
    });

    test(
      'a more specific block keeps its reason and the sheet stays torn (D-20)',
      () {
        final viewer = buildViewer(
          quests: buildLanes(pendingQuest: laneJson(questId: 'other')),
        );
        final standing = standingOf(
          buildQuest(type: 'heal', noEffect: true),
          viewer,
        );
        expect(standing.availability, QuestAvailability.laneBusy);
        expect(standing.isTorn, isTrue);
      },
    );

    test("the lane owner's heal stays tornForOwner (D-20)", () {
      final viewer = buildViewer(
        quests: buildLanes(pendingQuest: laneJson(questId: 'q-1')),
      );
      final standing = standingOf(
        buildQuest(type: 'heal', noEffect: true),
        viewer,
      );
      expect(standing.availability, QuestAvailability.tornForOwner);
      expect(standing.isTorn, isTrue);
    });

    test('the flag is read for any type, no rule on the type (D-20)', () {
      final standing = standingOf(
        buildQuest(type: 'job', noEffect: true),
        buildViewer(),
      );
      expect(standing.availability, QuestAvailability.noEffect);
      expect(standing.isTorn, isTrue);
    });

    test('a quest with noEffect asks for no travel preview (D-20)', () {
      expect(
        needsTravelPreview(buildQuest(type: 'heal'), buildViewer()),
        isTrue,
      );
      expect(
        needsTravelPreview(
          buildQuest(type: 'heal', noEffect: true),
          buildViewer(),
        ),
        isFalse,
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

  group('enemy quests are single-player with a minimum rank '
      '(quick 261111-enm)', () {
    const seatShapes = <String, List<Map<String, dynamic>>>{
      'rank-free seat': [
        {'title': null, 'count': 1},
      ],
      'rank-exact seat written before the rule': [
        {'title': 'rookie', 'count': 1},
      ],
    };

    for (final MapEntry(key: shape, value: slots) in seatShapes.entries) {
      test('a legend can take a rookie enemy with the $shape '
          '(quick 261111-enm)', () {
        final standing = standingOf(
          buildQuest(type: 'enemy', minTitle: 'rookie', slots: slots),
          buildViewer(title: TitleType.legend),
        );

        expect(standing.availability, QuestAvailability.available);
        expect(standing.isTorn, isFalse);
      });

      test('an enemy with the $shape is full and torn once one player is '
          'registered (quick 261111-enm)', () {
        final taken = buildQuest(
          type: 'enemy',
          minTitle: 'rookie',
          slots: slots,
          registered: [
            {'character': 'c-2', 'title': 'legend'},
          ],
        );

        for (final title in TitleType.values) {
          final standing = standingOf(taken, buildViewer(title: title));
          expect(
            standing.availability,
            QuestAvailability.full,
            reason: title.name,
          );
          expect(standing.isTorn, isTrue, reason: title.name);
        }
      });
    }

    test('a rookie sees a paladin enemy torn for the title '
        '(quick 261111-enm)', () {
      final standing = standingOf(
        buildQuest(
          type: 'enemy',
          minTitle: 'paladin',
          slots: [
            {'title': 'paladin', 'count': 1},
          ],
        ),
        buildViewer(title: TitleType.rookie),
      );

      expect(standing.availability, QuestAvailability.titleMismatch);
      expect(standing.isTorn, isTrue);
    });

    test('a hand-written enemy with more seats is full after one player '
        '(quick 261111-enm)', () {
      final taken = buildQuest(
        type: 'enemy',
        slots: [
          {'title': null, 'count': 3},
        ],
        registered: [
          {'character': 'c-2', 'title': 'rookie'},
        ],
      );

      expect(availabilityOf(taken, buildViewer()), QuestAvailability.full);
    });

    test('a boss keeps its rank-exact seats: a legend never takes a paladin '
        'seat (quick 261111-enm)', () {
      final boss = buildQuest(
        type: 'boss',
        minTitle: 'paladin',
        slots: [
          {'title': 'paladin', 'count': 2},
        ],
      );

      final legend = standingOf(boss, buildViewer(title: TitleType.legend));
      expect(legend.availability, QuestAvailability.full);
      expect(legend.isTorn, isTrue);
      expect(
        availabilityOf(boss, buildViewer(title: TitleType.paladin)),
        QuestAvailability.available,
      );
    });
  });
}
