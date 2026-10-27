import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';

void main() {
  group('fromWire', () {
    test('parses the five outcomes of the BE enum', () {
      expect(QuestOutcome.fromWire('success'), QuestOutcome.success);
      expect(QuestOutcome.fromWire('failure'), QuestOutcome.failure);
      expect(QuestOutcome.fromWire('rescued'), QuestOutcome.rescued);
      expect(QuestOutcome.fromWire('death'), QuestOutcome.death);
      expect(QuestOutcome.fromWire('gmCompleted'), QuestOutcome.gmCompleted);
    });

    test('returns null for unknown or non-string values', () {
      expect(QuestOutcome.fromWire('combat'), isNull);
      expect(QuestOutcome.fromWire(null), isNull);
      expect(QuestOutcome.fromWire(3), isNull);
    });
  });

  group('label', () {
    test('gives the Italian sheet header of every outcome', () {
      expect(QuestOutcome.success.label, 'Vittoria');
      expect(QuestOutcome.failure.label, 'Sconfitta');
      expect(QuestOutcome.rescued.label, 'Sei stato salvato');
      expect(QuestOutcome.death.label, 'È morto');
      expect(QuestOutcome.gmCompleted.label, 'Missione completata');
    });
  });
}
