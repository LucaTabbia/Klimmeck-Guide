import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/utils/quest_outcome_lines.dart';

import '../helpers/fixtures/quest_result_fixtures.dart';

void main() {
  group('arrestLine', () {
    test('an arrest reads «Sei stato arrestato.» with no hard-coded duration '
        '(quick 261110-cgd)', () {
      final line = arrestLine(questResult(arrestResultJson()));

      expect(line, 'Sei stato arrestato.');
      expect(line, isNot(contains('ore')));
    });

    test('any other result has no arrest line (quick 261110-cgd)', () {
      expect(arrestLine(questResult(questResultJson())), isNull);
      expect(arrestLine(questResult(guardEncounterResultJson())), isNull);
    });
  });

  group('confiscatedCoinsOf', () {
    test('the server coins of an arrest (quick 261110-cgd)', () {
      expect(
        confiscatedCoinsOf(questResult(arrestResultJson())),
        const Coins(silver: 7, copper: 50),
      );
    });

    test('null or zero coins show nothing (quick 261110-cgd)', () {
      expect(
        confiscatedCoinsOf(questResult(arrestResultJson(coinsLost: null))),
        isNull,
      );
      expect(
        confiscatedCoinsOf(
          questResult(
            arrestResultJson(
              coinsLost: const {'gold': 0, 'silver': 0, 'copper': 0},
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('guardEncounterLine', () {
    test('a won encounter says the pay was doubled (quick 261110-cgd)', () {
      expect(
        guardEncounterLine(questResult(guardEncounterResultJson())),
        'Scontro durante la guardia: vittoria, paga raddoppiata',
      );
    });

    test('a lost encounter says defeat (quick 261110-cgd)', () {
      expect(
        guardEncounterLine(
          questResult(guardEncounterResultJson(outcome: 'failure')),
        ),
        'Scontro durante la guardia: sconfitta',
      );
    });

    test('no encounter, no line (quick 261110-cgd)', () {
      expect(guardEncounterLine(questResult(questResultJson())), isNull);
    });
  });
}
