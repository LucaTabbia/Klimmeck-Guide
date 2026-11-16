import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';

import '../helpers/fixtures/quest_fixtures.dart';

void main() {
  test('fromJson parses pointsSpent, startDate, waitingTime and quest id', () {
    final lane = PendingQuest.fromJson(laneJson(pointsSpent: 3000));
    expect(lane.pointsSpent, 3000);
    expect(lane.startDate, DateTime.parse('2026-10-21T10:00:00.000Z'));
    expect(lane.quest!.id, 'q-1');
    expect(lane.waitingTime, 60000);
  });

  test('a null startDate is kept (traveling to the quest marker)', () {
    expect(PendingQuest.fromJson(laneJson(startDate: null)).startDate, isNull);
  });

  test('an absent pointsSpent is null', () {
    final json = laneJson()..remove('pointsSpent');
    expect(PendingQuest.fromJson(json).pointsSpent, isNull);
  });

  test('toJson emits pointsSpent and props include it', () {
    final lane = PendingQuest.fromJson(laneJson(pointsSpent: 5));
    expect(lane.toJson()['pointsSpent'], 5);
    expect(lane, PendingQuest.fromJson(laneJson(pointsSpent: 5)));
    expect(lane == PendingQuest.fromJson(laneJson(pointsSpent: 6)), isFalse);
    expect(lane.copyWith(pointsSpent: 9).pointsSpent, 9);
  });

  group('arrivedAt', () {
    const arrival = '2026-10-25T09:30:00.000Z';

    test('fromJson reads arrivedAt and keeps it null when absent', () {
      expect(
        PendingQuest.fromJson(laneJson(arrivedAt: arrival)).arrivedAt,
        DateTime.parse(arrival),
      );
      expect(
        PendingQuest.fromJson(laneJson()..remove('arrivedAt')).arrivedAt,
        isNull,
      );
    });

    test('toJson, copyWith and props include arrivedAt', () {
      final lane = PendingQuest.fromJson(laneJson(arrivedAt: arrival));
      expect(
        lane.toJson()['arrivedAt'],
        DateTime.parse(arrival).toIso8601String(),
      );
      expect(lane == PendingQuest.fromJson(laneJson()), isFalse);
      final later = DateTime.utc(2026, 10, 25, 10);
      expect(lane.copyWith(arrivedAt: later).arrivedAt, later);
    });

    test('a lane without startDate nor arrivedAt is travelling', () {
      final lane = PendingQuest.fromJson(laneJson(startDate: null));
      expect(lane.isTravelling, isTrue);
      expect(lane.isWaitingForParty, isFalse);
    });

    test('a lane on the marker without startDate waits for the party', () {
      final lane = PendingQuest.fromJson(
        laneJson(startDate: null, arrivedAt: arrival),
      );
      expect(lane.isTravelling, isFalse);
      expect(lane.isWaitingForParty, isTrue);
    });

    test('a started lane is neither travelling nor waiting', () {
      final lane = PendingQuest.fromJson(laneJson(arrivedAt: arrival));
      expect(lane.isTravelling, isFalse);
      expect(lane.isWaitingForParty, isFalse);
    });
  });

  group('learning part (BE Phase 24)', () {
    Map<String, dynamic> learningLaneJson({
      Object? learningSpell = _learningSpellJson,
      String? startDate = '2026-11-16T10:00:00.000Z',
      Object? waitingTime = 1800000,
    }) => laneJson(startDate: startDate)
      ..['learningSpell'] = learningSpell
      ..['waitingTime'] = waitingTime;

    test('parses the spell being learned (D-26)', () {
      final lane = PendingQuest.fromJson(learningLaneJson());
      expect(lane.learningSpell?.id, 's-1');
      expect(lane.learningSpell?.name, 'Dardo');
      expect(lane.isLearning, isTrue);
    });

    test('reads no learning spell when the key is absent, null or not a map '
        '(D-26)', () {
      final payloads = [
        laneJson(),
        learningLaneJson(learningSpell: null),
        learningLaneJson(learningSpell: 's-1'),
      ];
      for (final json in payloads) {
        final lane = PendingQuest.fromJson(json);
        expect(lane.learningSpell, isNull, reason: '$json');
        expect(lane.isLearning, isFalse, reason: '$json');
      }
    });

    test('the learning part ends at startDate + waitingTime (D-26)', () {
      expect(
        PendingQuest.fromJson(learningLaneJson()).learningEndsAt,
        DateTime.utc(2026, 11, 16, 10, 30),
      );
    });

    test('has no learning end outside the learning part or without its '
        'dates (D-26)', () {
      expect(PendingQuest.fromJson(laneJson()).learningEndsAt, isNull);
      expect(
        PendingQuest.fromJson(learningLaneJson(startDate: null)).learningEndsAt,
        isNull,
      );
      expect(
        PendingQuest.fromJson(
          learningLaneJson(waitingTime: null),
        ).learningEndsAt,
        isNull,
      );
    });

    test(
      'learningSpell takes part in equality, toJson and copyWith (D-26)',
      () {
        final learning = PendingQuest.fromJson(learningLaneJson());
        final researching = PendingQuest.fromJson(
          learningLaneJson(learningSpell: null),
        );
        expect(learning == researching, isFalse);
        expect(learning, PendingQuest.fromJson(learningLaneJson()));
        expect(learning.toJson()['learningSpell'], 's-1');
        expect(
          researching.copyWith(learningSpell: learning.learningSpell),
          learning,
        );
      },
    );

    test(
      'a travelling or waiting lane is unchanged by the new field (D-26)',
      () {
        final travelling = PendingQuest.fromJson(
          learningLaneJson(startDate: null),
        );
        expect(travelling.isTravelling, isTrue);
        expect(travelling.isWaitingForParty, isFalse);
        final waiting = PendingQuest.fromJson(
          laneJson(startDate: null, arrivedAt: '2026-11-16T09:00:00.000Z'),
        );
        expect(waiting.isWaitingForParty, isTrue);
        expect(waiting.isLearning, isFalse);
      },
    );
  });
}

const Map<String, dynamic> _learningSpellJson = {
  'id': 's-1',
  'name': 'Dardo',
  'origin': 'arcane',
  'requiredLearnTime': 1800000,
};
