import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/quest_state_label.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  PendingQuest lane({String? startDate = '2026-10-21T10:00:00.000Z'}) =>
      PendingQuest.fromJson(laneJson(startDate: startDate));

  test('while travelling the label is In viaggio for every type', () {
    for (final type in [...QuestType.values, null]) {
      expect(questStateLabel(lane(startDate: null), type), 'In viaggio');
    }
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
      expect(questStateLabel(lane(), type), label, reason: type.name);
    });
    expect(questStateLabel(lane(), null), 'In corso…');
  });
}
