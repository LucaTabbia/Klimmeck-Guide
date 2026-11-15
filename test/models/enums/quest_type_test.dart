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

    test('the arcane quest type keeps the label Magia (D-13, D-20)', () {
      expect(QuestType.arcane.label, 'Magia');
      expect(QuestType.fromWire('arcane'), QuestType.arcane);
    });

    test('every quest type has a non-empty label', () {
      for (final type in QuestType.values) {
        expect(type.label, isNotEmpty, reason: type.name);
      }
    });
  });

  group('wire boundary', () {
    test('every quest type round-trips through its wire name (D-09)', () {
      for (final type in QuestType.values) {
        expect(QuestType.fromWire(type.wireName), type, reason: type.name);
      }
    });

    test('the wire names of the thirteen types (D-09, D-20)', () {
      expect(QuestType.values.map((type) => type.wireName), [
        'hunt',
        'aid',
        'enemy',
        'worldMission',
        'boss',
        'dungeon',
        'story',
        'study',
        'arcane',
        'heal',
        'job',
        'crime',
        'guard',
      ]);
    });

    test('the legacy wire value magic reads as arcane (D-20)', () {
      expect(QuestType.fromWire('magic'), QuestType.arcane);
    });

    test('nothing writes magic: the wire name of arcane is arcane (D-20)', () {
      expect(QuestType.arcane.wireName, 'arcane');
      expect(
        QuestType.values.map((type) => type.wireName),
        isNot(contains('magic')),
      );
    });

    test('fromWire reads null for an unknown or non-string value (D-09)', () {
      expect(QuestType.fromWire('treasure'), isNull);
      expect(QuestType.fromWire(null), isNull);
      expect(QuestType.fromWire(7), isNull);
      expect(QuestType.fromWire(''), isNull);
    });
  });
}
