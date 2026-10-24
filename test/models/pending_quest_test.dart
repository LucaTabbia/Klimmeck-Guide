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
}
