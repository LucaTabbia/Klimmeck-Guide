import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

import '../../helpers/fixtures/quest_result_fixtures.dart';

void main() {
  group('parsing per outcome', () {
    test('parses every field of a success', () {
      final result = questResult(questResultJson());

      expect(result.id, 'result-1');
      expect(result.outcome, QuestOutcome.success);
      expect(result.resolvedAt, DateTime.utc(2026, 10, 27, 12));
      expect(result.resolvedAt, questResultResolvedAt);
      expect(result.resolvedAt.isUtc, isTrue);
      expect(result.characterId, 'c-1');
      expect(result.userId, 'u-1');
      expect(result.quest.id, 'q-1');
      expect(result.quest.type, QuestType.hunt);
      expect(result.quest.title, 'Lupi di Valantar');
      expect(result.hpBefore, 900);
      expect(result.hpAfter, 640);
      expect(result.maxLifePoints, 1200);
      expect(result.injuriesAdded, [InjuryType.deepCut]);
      expect(result.consumablesUsed, hasLength(1));
      expect(result.consumablesUsed.single.item!.isLoot, isTrue);
      expect(result.spellsUsed, hasLength(1));
      expect(result.spellsUsed.single.usages, 2);
      expect(result.spellsUsed.single.spell!.name, 'Dardo di fuoco');
      expect(result.rewards.coins, const Coins(silver: 3, copper: 20));
      expect(result.rewards.items, hasLength(1));
      expect(result.rewards.items.single.item!.isEquipment, isTrue);
      expect(result.xpBefore, 200);
      expect(result.xpGained, 60);
      expect(result.xpAfter, 260);
      expect(result.levelBefore, 1);
      expect(result.levelAfter, 2);
      expect(result.titleBefore, TitleType.rookie);
      expect(result.titleAfter, TitleType.rookie);
      expect(result.enemy!.name, 'Lupo grigio');
      expect(result.enemy!.imagePath, 'enemies/wolf.png');
      expect(result.spellLearned, isNull);
      expect(result.rescuedCharacters, isEmpty);
      expect(result.acknowledgedAt, isNull);
    });

    test('a failure has no rewards and no xp', () {
      final result = questResult(failureResultJson());

      expect(result.outcome, QuestOutcome.failure);
      expect(result.rewards.items, isEmpty);
      expect(result.rewards.coins, const Coins());
      expect(result.xpGained, 0);
    });

    test('a rescue has the aid as quest and no hp change', () {
      final result = questResult(rescuedResultJson());

      expect(result.outcome, QuestOutcome.rescued);
      expect(result.quest.type, QuestType.aid);
      expect(result.hpBefore, result.hpAfter);
    });

    test('a death has the aid as quest and no hp change', () {
      final result = questResult(deathResultJson(character: 'c-9'));

      expect(result.outcome, QuestOutcome.death);
      expect(result.characterId, 'c-9');
      expect(result.quest.type, QuestType.aid);
      expect(result.hpBefore, result.hpAfter);
    });

    test('a GM completion has no enemy', () {
      final result = questResult(gmCompletedResultJson());

      expect(result.outcome, QuestOutcome.gmCompleted);
      expect(result.enemy, isNull);
      expect(result.quest.type, QuestType.story);
      expect(result.titleAfter, TitleType.adventurer);
    });

    test('a rescuer success counts the saved adventurers', () {
      final result = questResult(rescuerSuccessResultJson());

      expect(result.rescuedCharacters, ['c-2', 'c-3']);
      expect(result.rescuedCharacters.length, 2);
    });

    test('parses the learned spell', () {
      final result = questResult(
        questResultJson(spellLearned: {'id': 'spell-9', 'name': 'Scudo'}),
      );

      expect(result.spellLearned!.id, 'spell-9');
      expect(result.spellLearned!.name, 'Scudo');
    });
  });

  group('derived getters', () {
    test('isDeath is true only for a death', () {
      expect(questResult(deathResultJson()).isDeath, isTrue);
      expect(questResult(successResultJson()).isDeath, isFalse);
      expect(questResult(rescuedResultJson()).isDeath, isFalse);
    });

    test('hasLevelChanged compares the levels', () {
      expect(questResult(successResultJson()).hasLevelChanged, isTrue);
      expect(questResult(failureResultJson()).hasLevelChanged, isFalse);
    });

    test('hasTitleChanged compares the titles', () {
      expect(questResult(gmCompletedResultJson()).hasTitleChanged, isTrue);
      expect(questResult(successResultJson()).hasTitleChanged, isFalse);
    });

    test('hasRewards is true with coins or items', () {
      expect(questResult(successResultJson()).hasRewards, isTrue);
      expect(questResult(failureResultJson()).hasRewards, isFalse);
      expect(
        questResult(questResultJson(rewardItems: const [])).hasRewards,
        isTrue,
      );
      expect(
        questResult(
          questResultJson(coins: const {'gold': 0, 'silver': 0, 'copper': 0}),
        ).hasRewards,
        isTrue,
      );
    });
  });

  group('tolerance', () {
    test('an unknown quest type keeps the title', () {
      final result = questResult(questResultJson(questType: 'raid'));

      expect(result.quest.type, isNull);
      expect(result.quest.title, 'Lupi di Valantar');
    });

    test('a spell usage with a null spell survives', () {
      final result = questResult(
        questResultJson(
          spellsUsed: [
            {'usages': 1, 'spell': null},
          ],
        ),
      );

      expect(result.spellsUsed, hasLength(1));
      expect(result.spellsUsed.single.usages, 1);
      expect(result.spellsUsed.single.spell, isNull);
    });

    test('an unknown injury name is skipped', () {
      final result = questResult(
        questResultJson(injuriesAdded: const ['deepCut', 'dragonBite']),
      );

      expect(result.injuriesAdded, [InjuryType.deepCut]);
    });

    test('an orphan consumable is skipped', () {
      final result = questResult(
        questResultJson(
          consumablesUsed: [
            lootRewardJson(),
            {'quantity': 1, 'item': null},
          ],
        ),
      );

      expect(result.consumablesUsed, hasLength(1));
    });

    test('an orphan reward item is skipped', () {
      final result = questResult(
        questResultJson(
          rewardItems: [
            {'quantity': 2, 'item': null},
          ],
        ),
      );

      expect(result.rewards.items, isEmpty);
    });

    test('an unknown title is null', () {
      final result = questResult(questResultJson(titleAfter: 'archmage'));

      expect(result.titleAfter, isNull);
      expect(result.titleBefore, TitleType.rookie);
    });

    test('acknowledgedAt is parsed as a UTC instant when present', () {
      final result = questResult(
        questResultJson(acknowledgedAt: '2026-10-27T12:05:00.000Z'),
      );

      expect(result.acknowledgedAt, DateTime.utc(2026, 10, 27, 12, 5));
      expect(result.acknowledgedAt!.isUtc, isTrue);
    });

    test('an enemy with locations never reaches Enemy.fromJson', () {
      final json = questResultJson();
      (json['enemy'] as Map<String, dynamic>)['locations'] = ['forest'];

      expect(questResult(json).enemy!.name, 'Lupo grigio');
    });
  });

  group('tryFromJson', () {
    test('parses a valid payload', () {
      expect(QuestResult.tryFromJson(successResultJson())?.id, 'result-1');
    });

    test('returns null for non-map values', () {
      expect(QuestResult.tryFromJson(null), isNull);
      expect(QuestResult.tryFromJson('result-1'), isNull);
    });

    test('returns null when a required scalar is missing or malformed', () {
      expect(QuestResult.tryFromJson(questResultJson()..remove('id')), isNull);
      expect(
        QuestResult.tryFromJson(questResultJson(outcome: 'combat')),
        isNull,
      );
      expect(
        QuestResult.tryFromJson(questResultJson()..['hpBefore'] = 'x'),
        isNull,
      );
      expect(
        QuestResult.tryFromJson(questResultJson(resolvedAt: 'not-a-date')),
        isNull,
      );
    });
  });

  group('round trip', () {
    final payloads = {
      'success': successResultJson(),
      'failure': failureResultJson(),
      'rescued': rescuedResultJson(),
      'death': deathResultJson(),
      'gmCompleted': gmCompletedResultJson(),
      'rescuer': rescuerSuccessResultJson(),
      'acknowledged': questResultJson(
        acknowledgedAt: '2026-10-27T12:05:00.000Z',
        spellLearned: {'id': 'spell-9', 'name': 'Scudo'},
      ),
    };

    for (final entry in payloads.entries) {
      test('fromJson(toJson()) is equal for ${entry.key}', () {
        final result = questResult(entry.value);

        expect(QuestResult.fromJson(result.toJson()), result);
      });
    }

    test('toJson writes resolvedAt as a UTC instant', () {
      final json = questResult(successResultJson()).toJson();

      expect(json['resolvedAt'], endsWith('Z'));
    });

    test('lists are unmodifiable', () {
      final result = questResult(successResultJson());

      expect(
        () => result.injuriesAdded.add(InjuryType.blackEye),
        throwsUnsupportedError,
      );
      expect(() => result.rescuedCharacters.add('c-4'), throwsUnsupportedError);
      expect(() => result.consumablesUsed.clear(), throwsUnsupportedError);
      expect(() => result.spellsUsed.clear(), throwsUnsupportedError);
      expect(() => result.rewards.items.clear(), throwsUnsupportedError);
    });
  });
}
