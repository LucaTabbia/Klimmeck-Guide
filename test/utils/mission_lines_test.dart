import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/repository/mission_in_progress.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

void main() {
  test('the pawn and Journal label is «Missione in corso» (D-30)', () {
    expect(missionInProgressLabel, 'Missione in corso');
  });

  test("the refusal line is «Sei impegnato in una missione: aspetta l'esito» "
      '(D-30)', () {
    expect(
      missionInProgressRefusalLine,
      "Sei impegnato in una missione: aspetta l'esito",
    );
  });

  test('every mission that runs by itself names what the character is doing '
      '(UAT 2026-11-14)', () {
    expect(
      {for (final type in QuestType.values) type: missionActivityLabelOf(type)},
      {
        QuestType.hunt: 'Cacciando…',
        QuestType.aid: 'Soccorrendo…',
        QuestType.enemy: 'Combattendo…',
        QuestType.boss: 'Combattendo…',
        QuestType.dungeon: 'Esplorando…',
        QuestType.study: 'Studiando…',
        QuestType.magic: 'Studiando…',
        QuestType.heal: 'In cura…',
        QuestType.job: 'Lavorando…',
        QuestType.crime: 'Tramando…',
        QuestType.guard: 'Di guardia…',
        QuestType.worldMission: null,
        QuestType.story: null,
      },
    );
    expect(missionActivityLabelOf(null), isNull);
  });

  test('the refusal code is MISSION_IN_PROGRESS (D-11)', () {
    expect(missionInProgressCode, 'MISSION_IN_PROGRESS');
  });
}
