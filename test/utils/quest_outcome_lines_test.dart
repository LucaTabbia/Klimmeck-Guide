import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/quest_result/quest_companion_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
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

  group('companion fate (BE Phase 23)', () {
    const wounded = QuestCompanionOutcome(
      name: 'Fenrir',
      lifeBefore: 300,
      lifePoints: 120,
      maxLifePoints: 300,
    );
    const unharmed = QuestCompanionOutcome(
      name: 'Fenrir',
      lifeBefore: 300,
      lifePoints: 300,
      maxLifePoints: 300,
    );
    final resolvedAt = DateTime.utc(2026, 10, 27, 12);
    QuestCompanionOutcome defeated({DateTime? fullLifeAt}) =>
        QuestCompanionOutcome(
          name: 'Fenrir',
          lifeBefore: 300,
          lifePoints: 0,
          maxLifePoints: 300,
          isDefeated: true,
          fullLifeAt: fullLifeAt,
        );

    test('life line when the life dropped: «Fenrir: 120 / 300 di vita» '
        '(D-10, D-27)', () {
      expect(companionFightLifeLine(wounded), 'Fenrir: 120 / 300 di vita');
    });

    test('no life line when unharmed or defeated (D-10)', () {
      expect(companionFightLifeLine(unharmed), isNull);
      expect(
        companionFightLifeLine(
          defeated(fullLifeAt: DateTime.utc(2026, 10, 27, 22)),
        ),
        isNull,
      );
      expect(companionFightLifeLine(null), isNull);
    });

    test('defeat line with fullLifeAt − resolvedAt: «… tornerà fra 10 h» '
        '(D-10, D-27)', () {
      expect(
        companionDefeatResultLine(
          defeated(fullLifeAt: DateTime.utc(2026, 10, 27, 22)),
          resolvedAt,
        ),
        'Fenrir è stato sconfitto: riposa e tornerà fra 10 h',
      );
      expect(companionDefeatResultLine(wounded, resolvedAt), isNull);
      expect(companionDefeatResultLine(null, resolvedAt), isNull);
    });

    test('a defeat without a usable date reads the name and the defeat only '
        '(D-10)', () {
      for (final fullLifeAt in <DateTime?>[
        null,
        resolvedAt,
        DateTime.utc(2026),
      ]) {
        expect(
          companionDefeatResultLine(
            defeated(fullLifeAt: fullLifeAt),
            resolvedAt,
          ),
          'Fenrir è stato sconfitto',
          reason: '$fullLifeAt',
        );
      }
    });

    test('the xp line names the companion when served (D-20, D-27)', () {
      expect(
        companionXpGainedLine(12, name: 'Fenrir'),
        'Fenrir guadagna 12 PE',
      );
      expect(companionXpGainedLine(12), 'Il tuo compagno guadagna 12 PE');
      expect(
        companionXpGainedLine(12, name: '  '),
        'Il tuo compagno guadagna 12 PE',
      );
      expect(companionXpGainedLine(0, name: 'Fenrir'), isNull);
    });

    test('«Prosegui a piedi» only when on foot and still travelling '
        '(D-28)', () {
      final onFoot = questResult(
        ambushWonResultJson()..['ambush']['onFoot'] = true,
      );
      final carried = questResult(
        ambushLostResultJson()..['ambush']['onFoot'] = true,
      );

      expect(onFootLineOf(onFoot), 'Prosegui a piedi');
      expect(onFootLineOf(carried), isNull);
      expect(onFootLineOf(questResult(ambushLostResultJson())), isNull);
      expect(onFootLineOf(questResult(questResultJson())), isNull);
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
        'Caduto al 4° piano su 8, in esplorazione',
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
        'Caduto al 4° piano su 8, in uno scontro',
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
        'Caduto al 4° piano su 8',
      );
    });

    test('the rescuer who saves the wounded reads the reached turn (D-21)', () {
      expect(
        lineOf(aidDungeonResultJson()),
        'Soccorso effettuato al raggiungimento del 4° piano su 8',
      );
    });

    test('a lost rescue reads like a fall (D-21)', () {
      expect(
        lineOf(
          aidDungeonResultJson(
            outcome: 'failure',
            turnsCompleted: 2,
            lastTurn: 3,
            lastTurnKind: 'exploration',
            stagesCleared: 1,
          ),
        ),
        'Caduto al 3° piano su 8, in esplorazione',
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
        'Piani superati: 8 su 8',
      );
    });

    test('the FE never adds one to the served turn (D-22)', () {
      final line = lineOf(
        dungeonResultJson(turnsTotal: 8, turnsCompleted: 3, lastTurn: 4),
      );

      expect(line, contains('4° piano'));
      expect(line, isNot(contains('5° piano')));
    });

    test('without the last turn a fall reads the completed turns (D-21)', () {
      expect(
        lineOf(dungeonResultJson(turnsTotal: 8, turnsCompleted: 3)),
        'Piani superati: 3 su 8',
      );
    });

    test('a won rescue without the last turn reads the completed turns '
        '(D-21)', () {
      expect(
        lineOf(aidDungeonResultJson(lastTurn: null)),
        'Piani superati: 4 su 8',
      );
    });

    test('missing completed turns read as zero (D-21)', () {
      expect(
        lineOf(dungeonResultJson(turnsTotal: 8)),
        'Piani superati: 0 su 8',
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

  group('research lines (Phase 23 D-29, D-31)', () {
    QuestResult found(Map<String, dynamic>? spell) =>
        questResult(questResultJson(spellFound: spell));

    test('names the spell found by the research (D-31)', () {
      expect(
        spellFoundLine(found({'id': 's-1', 'name': 'Dardo'})),
        'Magia scoperta: Dardo',
      );
      expect(
        spellFoundLine(found({'id': 's-1', 'name': '  '})),
        'Magia scoperta',
      );
      expect(
        spellFoundLine(found({'id': 's-1', 'name': null})),
        'Magia scoperta',
      );
      expect(spellFoundLine(questResult(questResultJson())), isNull);
    });

    test('prints the learning time of the spell found (D-31)', () {
      Map<String, dynamic> spell(Object? time) => {
        'id': 's-1',
        'name': 'Dardo',
        'requiredLearnTime': time,
      };

      expect(
        spellLearningTimeLine(found(spell(1800000))),
        'Tempo di apprendimento: 30 min',
      );
      expect(
        spellLearningTimeLine(found(spell(43200000))),
        'Tempo di apprendimento: 12 h',
      );
      for (final time in [null, 0, -1000]) {
        expect(
          spellLearningTimeLine(found(spell(time))),
          isNull,
          reason: '$time',
        );
      }
      expect(spellLearningTimeLine(questResult(questResultJson())), isNull);
    });

    test('a failed research has its own line (D-29)', () {
      expect(
        spellResearchFailedLine(
          questResult(questResultJson(spellResearchFailed: true)),
        ),
        'La ricerca non ha rivelato alcuna magia',
      );
      expect(
        spellResearchFailedLine(
          questResult(questResultJson(spellResearchFailed: false)),
        ),
        isNull,
      );
    });
  });
}
