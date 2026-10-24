import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest_cost_line.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('costLineOf', () {
    test('story shows balance and cost and flags an insufficient balance', () {
      final quest = buildQuest(type: 'story', requiredPoints: 3000);
      final short = costLineOf(quest, 1200)!;
      expect(short.text, 'Punti canale: 1200 / 3000');
      expect(short.isInsufficient, isTrue);
      expect(costLineOf(quest, 5000)!.isInsufficient, isFalse);
    });

    test('unknown balance shows the cost only and is not insufficient', () {
      final line = costLineOf(
        buildQuest(type: 'worldMission', requiredPoints: 800),
        null,
      )!;
      expect(line.text, 'Punti canale: 800');
      expect(line.isInsufficient, isFalse);
    });

    test('an enemy with requiredPoints has no cost line', () {
      expect(
        costLineOf(buildQuest(type: 'enemy', requiredPoints: 3000), 10),
        isNull,
      );
    });

    test('story without a positive cost has no cost line', () {
      expect(costLineOf(buildQuest(type: 'story'), 10), isNull);
      expect(
        costLineOf(buildQuest(type: 'story', requiredPoints: 0), 10),
        isNull,
      );
    });
  });
}
