import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';

void main() {
  group('label', () {
    test('quest types have an Italian label', () {
      expect(QuestType.hunt.label, 'Caccia');
      expect(QuestType.aid.label, 'Soccorso');
      expect(QuestType.enemy.label, 'Nemico');
      expect(QuestType.worldMission.label, 'Missione mondiale');
      expect(QuestType.boss.label, 'Boss');
      expect(QuestType.dungeon.label, 'Dungeon');
      expect(QuestType.story.label, 'Storia');
      expect(QuestType.study.label, 'Studio');
      expect(QuestType.heal.label, 'Cura');
      expect(QuestType.job.label, 'Lavoro');
      expect(QuestType.crime.label, 'Crimine');
      expect(QuestType.guard.label, 'Guardia');
    });

    test('every quest type has a non-empty label', () {
      for (final type in QuestType.values) {
        expect(type.label, isNotEmpty, reason: type.name);
      }
    });
  });
}
