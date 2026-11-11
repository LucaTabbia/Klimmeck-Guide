import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result_kind.dart';

import '../../helpers/fixtures/lore_fixtures.dart';
import '../../helpers/fixtures/quest_fixtures.dart';
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
      expect(result.quest!.id, 'q-1');
      expect(result.quest!.type, QuestType.hunt);
      expect(result.quest!.title, 'Lupi di Valantar');
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
      expect(result.enemies, hasLength(1));
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
      expect(result.quest!.type, QuestType.aid);
      expect(result.hpBefore, result.hpAfter);
    });

    test('a death has the aid as quest and no hp change', () {
      final result = questResult(deathResultJson(character: 'c-9'));

      expect(result.outcome, QuestOutcome.death);
      expect(result.characterId, 'c-9');
      expect(result.quest!.type, QuestType.aid);
      expect(result.hpBefore, result.hpAfter);
    });

    test('a GM completion has no enemies', () {
      final result = questResult(gmCompletedResultJson());

      expect(result.outcome, QuestOutcome.gmCompleted);
      expect(result.enemies, isEmpty);
      expect(result.quest!.type, QuestType.story);
      expect(result.titleAfter, TitleType.adventurer);
    });

    test('a rescuer success counts the saved adventurers', () {
      final result = questResult(rescuerSuccessResultJson());

      expect(result.rescuedCharacters, ['c-2', 'c-3']);
      expect(result.rescuedCharacters.length, 2);
    });

    test('parses the enemies fought in BE order (D-07)', () {
      final result = questResult(questResultJson());

      expect(result.enemies.single.enemy.name, 'Lupo grigio');
      expect(result.enemies.single.enemy.imagePath, 'enemies/wolf.png');
      expect(result.enemies.single.quantity, 1);
    });

    test('keeps xp of the enemies fought for the portrait (D-01)', () {
      final result = questResult(
        questResultJson(enemies: [questEnemyJson(xp: 21)]),
      );

      expect(result.enemies.single.enemy.xp, 21);
    });

    test('a dungeon carries stagesCleared and stagesTotal (D-07)', () {
      final result = questResult(dungeonResultJson());

      expect(result.stagesCleared, 1);
      expect(result.stagesTotal, 3);
      expect(result.enemies.length, 3);
      expect(result.enemies.map((entry) => entry.enemy.id), [
        'goblin',
        'goblin-chief',
        'troll',
      ]);
    });

    test('stages are null outside a dungeon (D-07)', () {
      final result = questResult(questResultJson());

      expect(result.stagesCleared, isNull);
      expect(result.stagesTotal, isNull);
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

  group('companion reward', () {
    test('parses rewards.pet as the companion obtained (D-07)', () {
      final result = questResult(
        questResultJson(rewardPet: {'id': 'pet-owl', 'name': 'Gufo reale'}),
      );

      expect(result.rewards.pet!.name, 'Gufo reale');
    });

    test('a pet-only reward is not empty (D-01)', () {
      final result = questResult(
        questResultJson(
          coins: const {'gold': 0, 'silver': 0, 'copper': 0},
          rewardItems: const [],
          rewardPet: {'id': 'pet-owl', 'name': 'Gufo reale'},
        ),
      );

      expect(result.rewards.isEmpty, isFalse);
      expect(result.hasRewards, isTrue);
    });

    test('no pet keeps the old emptiness rule (D-01)', () {
      final result = questResult(
        questResultJson(
          coins: const {'gold': 0, 'silver': 0, 'copper': 0},
          rewardItems: const [],
        ),
      );

      expect(result.rewards.isEmpty, isTrue);
    });

    test('a pet without id is ignored and the result kept (D-07)', () {
      final result = QuestResult.tryFromJson(
        questResultJson(rewardPet: {'name': 'x'}),
      );

      expect(result, isNotNull);
      expect(result!.rewards.pet, isNull);
    });
  });

  group('tolerance', () {
    test('an unknown quest type keeps the title', () {
      final result = questResult(questResultJson(questType: 'raid'));

      expect(result.quest!.type, isNull);
      expect(result.quest!.title, 'Lupi di Valantar');
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

    test('the BE 9.2 handoff payload parses with acknowledgedAt null', () {
      final json = deathResultJson()..['acknowledgedAt'] = null;

      final result = questResult(json);

      expect(result.isDeath, isTrue);
      expect(result.acknowledgedAt, isNull);
    });

    test('an enemy with locations never reaches Enemy.fromJson', () {
      final entry = questEnemyJson(imagePath: 'enemies/wolf.png');
      entry['enemy'] = <String, dynamic>{
        ...entry['enemy'] as Map<String, dynamic>,
        'locations': ['forest'],
      };

      final result = questResult(questResultJson(enemies: [entry]));

      expect(result.enemies.single.enemy.name, 'Lupo grigio');
    });

    test('drops a malformed enemies entry and keeps the result (D-01)', () {
      final result = QuestResult.tryFromJson(
        questResultJson(
          enemies: [
            questEnemyJson(),
            {'quantity': 1},
            'x',
          ],
        ),
      );

      expect(result, isNotNull);
      expect(result!.enemies, hasLength(1));
    });

    test('a missing enemies key gives an empty list (D-01)', () {
      final result = QuestResult.tryFromJson(
        questResultJson()..remove('enemies'),
      );

      expect(result, isNotNull);
      expect(result!.enemies, isEmpty);
    });

    test('a non-numeric stage counter is null, the result is kept (D-07)', () {
      final result = QuestResult.tryFromJson(
        questResultJson(stagesCleared: 1, stagesTotal: 'tre'),
      );

      expect(result, isNotNull);
      expect(result!.stagesTotal, isNull);
      expect(result.stagesCleared, 1);
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

  group('ambush reports (BE Phase 15)', () {
    test('a missing kind reads as a quest result (D-01)', () {
      final result = questResult(questResultJson());

      expect(result.kind, QuestResultKind.quest);
      expect(result.isAmbush, isFalse);
      expect(result.ambush, isNull);
      expect(result.quest!.title, 'Lupi di Valantar');
    });

    test('an unknown kind reads as a quest result (D-01)', () {
      final result = questResult(questResultJson()..['kind'] = 'raid');

      expect(result.kind, QuestResultKind.quest);
    });

    test('parses a won ambush without a quest (D-01)', () {
      final result = questResult(ambushWonResultJson());

      expect(result.isAmbush, isTrue);
      expect(result.quest, isNull);
      expect(result.outcome, QuestOutcome.success);
      expect(result.ambush!.nearCity.name, 'Andogan');
      expect(result.ambush!.reachedCity, isNull);
      expect(result.ambush!.at, result.resolvedAt);
      expect(result.rewards.coins.toCopper(), greaterThan(0));
      expect(result.xpGained, 35);
    });

    test('an ambush ignores a malformed quest block (D-01)', () {
      final result = questResult(
        ambushWonResultJson()..['quest'] = {'id': 'q-1'},
      );

      expect(result.isAmbush, isTrue);
      expect(result.quest, isNull);
    });

    test('parses a lost ambush with the city reached (D-01)', () {
      final result = questResult(ambushLostResultJson());

      expect(result.isAmbush, isTrue);
      expect(result.outcome, QuestOutcome.failure);
      expect(result.ambush!.reachedCity!.name, 'Bosa');
      expect(result.hpAfter, 1);
      expect(result.xpGained, 0);
    });

    test('drops an ambush without its report (D-01)', () {
      expect(
        QuestResult.tryFromJson(ambushWonResultJson()..remove('ambush')),
        isNull,
      );
      expect(
        QuestResult.tryFromJson(ambushWonResultJson()..['ambush'] = null),
        isNull,
      );
    });

    test('drops a quest result without its quest (D-01)', () {
      expect(
        QuestResult.tryFromJson(questResultJson()..['quest'] = null),
        isNull,
      );
    });

    test('ignores an ambush block on a quest result (D-01)', () {
      final result = questResult(
        questResultJson()
          ..['kind'] = 'quest'
          ..['ambush'] = ambushReportJson(),
      );

      expect(result.ambush, isNull);
    });

    test('results with a different ambush report are not equal (D-01)', () {
      expect(
        questResult(ambushWonResultJson()),
        isNot(
          questResult(
            ambushWonResultJson()
              ..['ambush'] = ambushReportJson(at: '2026-10-27T11:25:00.000Z'),
          ),
        ),
      );
    });
  });

  group('lore unlocked (BE Phase 16)', () {
    test('a missing loreUnlocked is an empty list (D-04)', () {
      final result = questResult(questResultJson()..remove('loreUnlocked'));

      expect(result.loreUnlocked, isEmpty);
    });

    test('parses the lore unlocked by the outcome in BE order (D-04)', () {
      final result = questResult(
        questResultJson(
          loreUnlocked: [
            loreRefJson(),
            loreRefJson(
              id: 'lore-runes',
              name: 'Rune antiche',
              type: 'knowledge',
            ),
          ],
        ),
      );

      expect(result.loreUnlocked.map((lore) => lore.id), [
        'lore-goblin',
        'lore-runes',
      ]);
      expect(result.loreUnlocked.map((lore) => lore.type), [
        LoreType.enemy,
        LoreType.knowledge,
      ]);
      expect(result.loreUnlocked.map((lore) => lore.name), [
        'Goblin',
        'Rune antiche',
      ]);
    });

    test('drops malformed entries and keeps the result (D-04)', () {
      final json = questResultJson(
        loreUnlocked: [
          'Goblin',
          {'name': 'Senza id', 'type': 'enemy'},
          {'id': 'l3', 'type': 'enemy'},
          {'id': 'l4', 'name': '', 'type': 'enemy'},
          loreRefJson(),
        ],
      );

      expect(QuestResult.tryFromJson(json), isNotNull);
      expect(questResult(json).loreUnlocked.map((lore) => lore.id), [
        'lore-goblin',
      ]);
    });

    test('keeps an entry with an unknown type, without type (D-16)', () {
      final result = questResult(
        questResultJson(loreUnlocked: [loreRefJson(type: 'dragon')]),
      );

      expect(result.loreUnlocked, hasLength(1));
      expect(result.loreUnlocked.single.type, isNull);
    });

    test('a non-list loreUnlocked is an empty list (D-04)', () {
      final result = questResult(
        questResultJson()..['loreUnlocked'] = 'lore-goblin',
      );

      expect(result.loreUnlocked, isEmpty);
    });

    test('results with different lore unlocked are not equal (D-04)', () {
      final withGoblin = questResult(
        questResultJson(loreUnlocked: [loreRefJson()]),
      );
      final withRunes = questResult(
        questResultJson(
          loreUnlocked: [
            loreRefJson(
              id: 'lore-runes',
              name: 'Rune antiche',
              type: 'knowledge',
            ),
          ],
        ),
      );

      expect(withGoblin, isNot(withRunes));
    });
  });

  group('injuriesHealed (BE Phase 18)', () {
    test('a result without injuriesHealed has an empty list (D-02)', () {
      final result = questResult(questResultJson()..remove('injuriesHealed'));

      expect(result.injuriesHealed, isEmpty);
    });

    test('parses the injuries healed (D-02)', () {
      final result = questResult(
        questResultJson(injuriesHealed: ['contusion', 'deepCut']),
      );

      expect(result.injuriesHealed, [InjuryType.contusion, InjuryType.deepCut]);
    });

    test('drops unknown names and keeps the result (D-02)', () {
      final json = questResultJson(injuriesHealed: ['contusion', 'dragonBite']);

      expect(QuestResult.tryFromJson(json), isNotNull);
      expect(questResult(json).injuriesHealed, [InjuryType.contusion]);
    });

    test(
      'a non-list injuriesHealed is an empty list and the result stays (D-02)',
      () {
        final json = questResultJson()..['injuriesHealed'] = 'contusion';

        expect(QuestResult.tryFromJson(json), isNotNull);
        expect(questResult(json).injuriesHealed, isEmpty);
      },
    );

    test('toJson writes the injuries healed (D-02)', () {
      final json = questResult(healResultJson()).toJson();

      expect(json['injuriesHealed'], ['contusion']);
    });

    test('props include injuriesHealed (D-02)', () {
      final healed = questResult(healResultJson());
      final notHealed = questResult(healResultJson(injuriesHealed: const []));

      expect(healed, isNot(notHealed));
    });
  });

  group('arrest and guard encounter (quick 261110-cgd)', () {
    test('a result without the new fields is neither arrested nor a guard '
        'encounter (quick 261110-cgd)', () {
      final result = questResult(questResultJson());

      expect(result.arrested, isFalse);
      expect(result.coinsLost, isNull);
      expect(result.guardEncounter, isFalse);
    });

    test('parses an arrest with the confiscated coins (quick 261110-cgd)', () {
      final result = questResult(arrestResultJson());

      expect(result.arrested, isTrue);
      expect(result.coinsLost, const Coins(silver: 7, copper: 50));
      expect(result.guardEncounter, isFalse);
    });

    test('parses a guard encounter (quick 261110-cgd)', () {
      final result = questResult(guardEncounterResultJson());

      expect(result.guardEncounter, isTrue);
      expect(result.arrested, isFalse);
      expect(result.coinsLost, isNull);
    });

    test('malformed fields fall back to free, false and null and the result '
        'stays (quick 261110-cgd)', () {
      final json = questResultJson()
        ..addAll({'arrested': 'yes', 'coinsLost': 12, 'guardEncounter': 1});

      final result = QuestResult.tryFromJson(json);

      expect(result, isNotNull);
      expect(result!.arrested, isFalse);
      expect(result.coinsLost, isNull);
      expect(result.guardEncounter, isFalse);
    });

    test('toJson round-trips the new fields (quick 261110-cgd)', () {
      final arrest = questResult(arrestResultJson());

      expect(questResult(arrest.toJson()), arrest);
      expect(arrest.toJson()['arrested'], isTrue);
      expect(arrest.toJson()['guardEncounter'], isFalse);
    });

    test('props include the new fields (quick 261110-cgd)', () {
      expect(
        questResult(arrestResultJson()),
        isNot(questResult(arrestResultJson(coinsLost: null))),
      );
      expect(
        questResult(guardEncounterResultJson()),
        isNot(
          questResult(guardEncounterResultJson()..['guardEncounter'] = false),
        ),
      );
    });
  });

  group('petXpGained (BE Phase 19)', () {
    test('parses the companion xp gained (D-03)', () {
      final result = questResult(questResultJson(petXpGained: 12));

      expect(result.petXpGained, 12);
    });

    test('an absent companion xp is 0 (D-03)', () {
      final json = questResultJson(petXpGained: 12)..remove('petXpGained');

      expect(QuestResult.tryFromJson(json), isNotNull);
      expect(questResult(json).petXpGained, 0);
    });

    test('a companion xp that is not a number is 0 (D-03)', () {
      for (final malformed in <Object?>['12', null, <Object?>[]]) {
        final json = questResultJson()..['petXpGained'] = malformed;

        expect(QuestResult.tryFromJson(json), isNotNull, reason: '$malformed');
        expect(questResult(json).petXpGained, 0, reason: '$malformed');
      }
    });

    test('a negative companion xp is 0 (D-03)', () {
      final json = questResultJson(petXpGained: -4);

      expect(QuestResult.tryFromJson(json), isNotNull);
      expect(questResult(json).petXpGained, 0);
    });

    test('toJson round-trips the companion xp (D-03)', () {
      final result = questResult(questResultJson(petXpGained: 12));

      expect(result.toJson()['petXpGained'], 12);
      expect(questResult(result.toJson()), result);
    });

    test('the companion xp is part of the props (D-03)', () {
      expect(
        questResult(questResultJson(petXpGained: 12)),
        isNot(questResult(questResultJson(petXpGained: 5))),
      );
    });
  });

  group('round trip', () {
    final payloads = {
      'heal': healResultJson(),
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
      'dungeon': dungeonResultJson(),
      'pet reward': questResultJson(
        rewardPet: {'id': 'pet-owl', 'name': 'Gufo reale'},
      ),
      'dungeon victory': dungeonResultJson(
        outcome: 'success',
        stagesCleared: 3,
      ),
      'ambush won': ambushWonResultJson(),
      'ambush lost': ambushLostResultJson(),
      'lore unlocked': questResultJson(
        loreUnlocked: [
          loreRefJson(),
          loreRefJson(
            id: 'lore-runes',
            name: 'Rune antiche',
            type: 'knowledge',
          ),
        ],
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
