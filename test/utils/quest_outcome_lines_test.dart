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

  group('companionXpGainedLine', () {
    test('prints the companion xp gained (D-03)', () {
      expect(companionXpGainedLine(12), 'Il tuo compagno guadagna 12 PE');
    });

    test('is null at zero and below (D-03)', () {
      expect(companionXpGainedLine(0), isNull);
      expect(companionXpGainedLine(-3), isNull);
    });
  });

  group('dungeonTurnLine (Phase 20)', () {
    String? lineOf(Map<String, dynamic> json) =>
        dungeonTurnLine(questResult(json));

    test('a fall in exploration names the turn and its kind (D-21)', () {
      expect(
        lineOf(
          dungeonResultJson(
            turnsTotal: 8,
            turnsCompleted: 3,
            lastTurn: 4,
            lastTurnKind: 'exploration',
          ),
        ),
        'Caduto al turno 4 di 8, in esplorazione',
      );
    });

    test('a fall in a fight names the turn and its kind (D-21)', () {
      expect(
        lineOf(
          dungeonResultJson(
            turnsTotal: 8,
            turnsCompleted: 3,
            lastTurn: 4,
            lastTurnKind: 'fight',
          ),
        ),
        'Caduto al turno 4 di 8, in uno scontro',
      );
    });

    test('a fall with an unknown kind names only the turn (D-21, D-22)', () {
      expect(
        lineOf(
          dungeonResultJson(
            turnsTotal: 8,
            turnsCompleted: 3,
            lastTurn: 4,
            lastTurnKind: 'teleport',
          ),
        ),
        'Caduto al turno 4 di 8',
      );
    });

    test('the rescuer who saves the wounded reads the reached turn (D-21)', () {
      expect(
        lineOf(aidDungeonResultJson()),
        'Ferito raggiunto al turno 4 di 8',
      );
    });

    test('a lost rescue reads like a fall (D-21)', () {
      expect(
        lineOf(
          aidDungeonResultJson(
            outcome: 'failure',
            lastTurn: 3,
            lastTurnKind: 'exploration',
          ),
        ),
        'Caduto al turno 3 di 8, in esplorazione',
      );
    });

    test('a cleared dungeon reads all the turns (D-21)', () {
      expect(
        lineOf(
          dungeonResultJson(
            outcome: 'success',
            stagesCleared: 3,
            turnsTotal: 8,
            turnsCompleted: 8,
            lastTurn: 8,
            lastTurnKind: 'fight',
          ),
        ),
        'Turni superati: 8 di 8',
      );
    });

    test('the FE never adds one to the served turn (D-22)', () {
      final line = lineOf(
        dungeonResultJson(turnsTotal: 8, turnsCompleted: 3, lastTurn: 4),
      );

      expect(line, contains('turno 4'));
      expect(line, isNot(contains('turno 5')));
    });

    test('without the last turn a fall reads the completed turns (D-21)', () {
      expect(
        lineOf(dungeonResultJson(turnsTotal: 8, turnsCompleted: 3)),
        'Turni superati: 3 di 8',
      );
    });

    test('a won rescue without the last turn reads the completed turns '
        '(D-21)', () {
      expect(
        lineOf(aidDungeonResultJson(lastTurn: null)),
        'Turni superati: 4 di 8',
      );
    });

    test('missing completed turns read as zero (D-21)', () {
      expect(
        lineOf(dungeonResultJson(turnsTotal: 8)),
        'Turni superati: 0 di 8',
      );
    });

    test('no turn line without turns (D-24)', () {
      expect(lineOf(dungeonResultJson()), isNull);
      expect(lineOf(successResultJson()), isNull);
    });

    test('no turn line with a zero total (D-24)', () {
      expect(
        lineOf(
          dungeonResultJson(turnsTotal: 0, turnsCompleted: 0, lastTurn: 0),
        ),
        isNull,
      );
    });

    test('no turn line with a negative total (D-24)', () {
      expect(lineOf(dungeonResultJson(turnsTotal: -1, lastTurn: 1)), isNull);
    });

    test('a rescued character gets no turn line (D-21)', () {
      expect(
        lineOf(rescuedResultJson()..addAll({'turnsTotal': 8, 'lastTurn': 4})),
        isNull,
      );
    });

    test('a death gets no turn line even with turns (D-21)', () {
      expect(
        lineOf(
          aidDungeonResultJson(
            outcome: 'death',
            lastTurn: 4,
            lastTurnKind: 'fight',
          ),
        ),
        isNull,
      );
    });

    test('a mission completed by the game master gets no turn line even with '
        'turns (D-21)', () {
      expect(
        lineOf(
          dungeonResultJson(
            outcome: 'gmCompleted',
            turnsTotal: 8,
            turnsCompleted: 8,
            lastTurn: 8,
            lastTurnKind: 'fight',
          ),
        ),
        isNull,
      );
    });
  });
}
