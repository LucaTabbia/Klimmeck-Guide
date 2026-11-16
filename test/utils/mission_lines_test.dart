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
      '(UAT 2026-11-14, D-09)', () {
    expect(
      {for (final type in QuestType.values) type: missionActivityLabelOf(type)},
      {
        QuestType.hunt: 'Cacciando…',
        QuestType.aid: 'Soccorrendo…',
        QuestType.enemy: 'Combattendo…',
        QuestType.boss: 'Combattendo…',
        QuestType.dungeon: 'Esplorando…',
        QuestType.study: 'Studiando…',
        QuestType.arcane: 'Ricercando…',
        QuestType.shamanic: 'Ricercando…',
        QuestType.theVoid: 'Ricercando…',
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

  test('the activity of a school quest is the research part (D-26, D-32)', () {
    for (final type in [
      QuestType.arcane,
      QuestType.shamanic,
      QuestType.theVoid,
    ]) {
      expect(missionActivityLabelOf(type), 'Ricercando…', reason: type.name);
    }
    expect(missionActivityLabelOf(QuestType.study), 'Studiando…');
    expect(spellResearchLabel, 'Ricercando…');
  });

  test('the paper of the learning part reads «Apprendimento…» (D-26)', () {
    expect(spellLearningPaperLabel, 'Apprendimento…');
  });

  test('the learning line names the spell and the time left (D-29)', () {
    expect(
      spellLearningLine('Dardo', const Duration(minutes: 28)),
      'Imparando «Dardo»: 28 min',
    );
    expect(
      spellLearningLine('Dardo', const Duration(minutes: 90)),
      'Imparando «Dardo»: 1 h 30 min',
    );
  });

  test('the learning line without time left only names the spell (D-29)', () {
    expect(spellLearningLine('Dardo', null), 'Imparando «Dardo»…');
    expect(spellLearningLine('Dardo', Duration.zero), 'Imparando «Dardo»…');
  });

  test(
    'the learning line without a readable name speaks of a spell (D-29)',
    () {
      for (final name in [null, '', '  ']) {
        expect(
          spellLearningLine(name, const Duration(minutes: 28)),
          'Imparando una magia: 28 min',
          reason: '$name',
        );
        expect(
          spellLearningLine(name, null),
          'Imparando una magia…',
          reason: '$name',
        );
      }
    },
  );

  test('the refusal code is MISSION_IN_PROGRESS (D-11)', () {
    expect(missionInProgressCode, 'MISSION_IN_PROGRESS');
  });
}
