import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';

import '../../helpers/fixtures/mission_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';

void main() {
  group('MissionFight', () {
    test('reads a simulated fight as served (D-04, D-21)', () {
      final fight = MissionFight.tryFromJson(
        missionFightJson(
          verdict: 'success',
          outcomes: [
            missionOutcomeJson(
              simulated: missionEffectsJson(
                hpAfter: 640,
                consumablesUsed: [missionItemUsageJson()],
                spellsUsed: [missionSpellUsageJson()],
              ),
            ),
          ],
        ),
      )!;

      expect(fight.verdict, MissionFightVerdict.success);
      expect(fight.verdict!.label, 'Vittoria');
      expect(fight.isSimulated, isTrue);
      expect(fight.enemies.single.quantity, 3);
      expect(fight.enemies.single.enemy.id, 'enemy-wolf');
      final simulated = fight.outcomeOf('char-aldo')!.simulated!;
      expect(simulated.hpAfter, 640);
      expect(simulated.injuriesAdded, [InjuryType.crushedRightHand]);
      expect(simulated.consumablesUsed, [
        const MissionItemUsage(itemId: potionItemId, quantity: 1),
      ]);
      expect(simulated.spellsUsed, [
        const MissionSpellUsage(spellId: fireballSpellId, usages: 1),
      ]);
      expect(MissionFightVerdict.failure.label, 'Sconfitta');
    });

    test('verdict null means not simulated (D-24)', () {
      final fight = MissionFight.tryFromJson(missionFightJson())!;

      expect(fight.verdict, isNull);
      expect(fight.isSimulated, isFalse);
      expect(fight.outcomeOf('char-aldo'), isNull);
    });

    test('effective prefers corrected over simulated (D-06)', () {
      final outcome = MissionFightOutcome.tryFromJson(
        missionOutcomeJson(
          simulated: missionEffectsJson(hpAfter: 500),
          corrected: missionEffectsJson(hpAfter: 650, injuriesAdded: []),
        ),
      )!;
      final onlySimulated = MissionFightOutcome.tryFromJson(
        missionOutcomeJson(simulated: missionEffectsJson(hpAfter: 500)),
      )!;
      final neither = MissionFightOutcome.tryFromJson(missionOutcomeJson())!;

      expect(outcome.effective!.hpAfter, 650);
      expect(outcome.effective!.injuriesAdded, isEmpty);
      expect(onlySimulated.effective!.hpAfter, 500);
      expect(neither.effective, isNull);
    });

    test('reads the start-of-fight bounds as served (D-14, D-17)', () {
      final outcome = MissionFightOutcome.tryFromJson(missionOutcomeJson())!;

      expect(outcome.characterId, 'char-aldo');
      expect(outcome.hpBefore, 800);
      expect(outcome.injuriesBefore, [InjuryType.blackEye]);
      expect(outcome.consumablesAvailable, [
        const MissionItemUsage(itemId: potionItemId, quantity: 2),
      ]);
      expect(outcome.spellsAvailable, [
        const MissionSpellUsage(spellId: fireballSpellId, usages: 2),
      ]);
    });

    test('an unknown injury is dropped, the outcome stays (Pitfall 8)', () {
      final outcome = MissionFightOutcome.tryFromJson(
        missionOutcomeJson(
          injuriesBefore: const ['blackEye', 'dragonCurse'],
          simulated: missionEffectsJson(
            injuriesAdded: const ['dragonCurse', 'crushedRightHand'],
          ),
        ),
      )!;

      expect(outcome.injuriesBefore, [InjuryType.blackEye]);
      expect(outcome.simulated!.injuriesAdded, [InjuryType.crushedRightHand]);
    });

    test(
      'an outcome without hpBefore is dropped, the fight stays (Pitfall 8)',
      () {
        final fight = MissionFight.tryFromJson(
          missionFightJson(
            verdict: 'failure',
            outcomes: [
              missionOutcomeJson(character: 'char-aldo', hpBefore: null),
              missionOutcomeJson(character: 'char-bea'),
            ],
          ),
        )!;

        expect(fight.outcomes.map((outcome) => outcome.characterId), [
          'char-bea',
        ]);
        expect(fight.verdict, MissionFightVerdict.failure);
      },
    );

    test('an unknown verdict reads null (Pitfall 8)', () {
      final fight = MissionFight.tryFromJson(
        missionFightJson(verdict: 'draw'),
      )!;

      expect(fight.verdict, isNull);
      expect(fight.isSimulated, isFalse);
    });

    test('a malformed enemy entry is dropped, the fight stays (Pitfall 8)', () {
      final fight = MissionFight.tryFromJson(
        missionFightJson(
          enemies: [
            {'enemy': null, 'quantity': 2},
            missionFightEnemyJson(quantity: 1),
          ],
        ),
      )!;

      expect(fight.enemies.single.quantity, 1);
    });

    test('a legendary enemy reads isLegendary (D-19)', () {
      final legendary = MissionEnemy.tryFromJson(
        missionEnemyJson(id: 'enemy-dragon', name: 'Drago', legendary: true),
      )!;
      final common = MissionEnemy.tryFromJson(missionEnemyJson())!;

      expect(legendary.isLegendary, isTrue);
      expect(common.isLegendary, isFalse);
      expect(common.name, 'Lupo');
      expect(common.imagePath, 'enemy_wolf_svg');
      expect(common.xp, 30);
      expect(common.lifePoints, 120);
    });
  });
}
