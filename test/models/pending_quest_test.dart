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
}
