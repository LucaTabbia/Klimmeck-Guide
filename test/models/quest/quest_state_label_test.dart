import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/quest_state_label.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  PendingQuest lane({
    String? startDate = '2026-10-21T10:00:00.000Z',
    String? arrivedAt,
  }) => PendingQuest.fromJson(
    laneJson(startDate: startDate, arrivedAt: arrivedAt),
  );

  PendingQuest waiting() =>
      lane(startDate: null, arrivedAt: '2026-10-25T09:30:00.000Z');

  test('while travelling the label is In viaggio for every type', () {
    for (final type in QuestType.values) {
      expect(
        questStateLabel(lane(startDate: null), buildQuest(type: type.name)),
        'In viaggio',
        reason: type.name,
      );
    }
    expect(questStateLabel(lane(startDate: null), null), 'In viaggio');
  });

  test('waiting on the marker counts the party against every seat', () {
    final boss = buildQuest(
      type: 'boss',
      slots: [
        {'title': null, 'count': 2},
        {'title': 'hero', 'count': 1},
      ],
      registered: [
        {'character': 'c-1', 'title': 'rookie'},
        {'character': 'c-2', 'title': 'hero'},
      ],
    );

    expect(questStateLabel(waiting(), boss), 'In attesa del gruppo 2/3');
  });

  test('waiting without the quest or its seats drops the count', () {
    expect(questStateLabel(waiting(), null), 'In attesa del gruppo');
    expect(
      questStateLabel(waiting(), buildQuest(slots: const [])),
      'In attesa del gruppo',
    );
  });

  test('once started the label depends on the type', () {
    const expected = {
      QuestType.enemy: 'In combattimento…',
      QuestType.boss: 'In combattimento…',
      QuestType.hunt: 'Cacciando…',
      QuestType.dungeon: 'Esplorando…',
      QuestType.job: 'Lavorando…',
      QuestType.heal: 'Guarendo…',
      QuestType.aid: 'Aiutando…',
      QuestType.study: 'Studiando…',
      QuestType.crime: 'In corso…',
      QuestType.guard: 'In corso…',
    };
    expected.forEach((type, label) {
      expect(
        questStateLabel(lane(), buildQuest(type: type.name)),
        label,
        reason: type.name,
      );
    });
    expect(questStateLabel(lane(), null), 'In corso…');
  });

  test('a started lane keeps the per-type label even with arrivedAt', () {
    expect(
      questStateLabel(
        lane(arrivedAt: '2026-10-25T09:30:00.000Z'),
        buildQuest(type: 'hunt'),
      ),
      'Cacciando…',
    );
  });
}
