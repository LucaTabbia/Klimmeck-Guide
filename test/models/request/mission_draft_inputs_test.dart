import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';

import '../../helpers/fixtures/mission_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';

const _aldo = 'char-aldo';
const _bea = 'char-bea';

MissionDraft _draft({List<Map<String, dynamic>> fights = const []}) =>
    MissionDraft.tryFromJson(
      missionDraftJson(
        step: 'fights',
        participants: [
          missionParticipantJson(),
          missionParticipantJson(character: _bea, name: 'Bea'),
        ],
        fights: fights,
      ),
    )!;

Map<String, dynamic> _wolves({int quantity = 3}) => missionFightEnemyJson(
  enemy: missionEnemyJson(id: 'enemy-wolf'),
  quantity: quantity,
);

Map<String, dynamic> _bandit() => missionFightEnemyJson(
  enemy: missionEnemyJson(id: 'enemy-bandit', name: 'Bandito'),
  quantity: 1,
);

/// Scontro simulato per Aldo e Bea; [aldoCorrected] / [beaCorrected] aggiungono la correzione servita.
Map<String, dynamic> _simulatedFight({
  List<Map<String, dynamic>>? enemies,
  Map<String, dynamic>? aldoCorrected,
  Map<String, dynamic>? beaCorrected,
}) => missionFightJson(
  enemies: enemies ?? [_wolves()],
  verdict: 'success',
  outcomes: [
    missionOutcomeJson(
      simulated: missionEffectsJson(hpAfter: 700),
      corrected: aldoCorrected,
    ),
    missionOutcomeJson(
      character: _bea,
      hpBefore: 900,
      simulated: missionEffectsJson(hpAfter: 820, injuriesAdded: const []),
      corrected: beaCorrected,
    ),
  ],
);

Map<String, dynamic> _fightJson(MissionFightInput input) => input.toJson();

List<Object?> _correctionsOf(MissionFightInput input) =>
    _fightJson(input)['corrections'] as List<Object?>;

MissionPrize _prize({Map<String, dynamic>? cure}) => MissionPrize.tryFromJson(
  missionPrizeJson(
    items: [
      {'item': potionItemId, 'quantity': 2},
    ],
    cure: cure,
  ),
)!;

void main() {
  group('MissionCorrection', () {
    test('a correction sends the full effect of the fight (D-14)', () {
      final correction = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(
          hpAfter: 600,
          injuriesAdded: [InjuryType.crushedRightHand],
          consumablesUsed: [
            MissionItemUsage(itemId: potionItemId, quantity: 1),
          ],
          spellsUsed: [MissionSpellUsage(spellId: fireballSpellId, usages: 1)],
        ),
      );

      expect(correction.toJson(), {
        'characterId': _aldo,
        'hpAfter': 600,
        'injuries': ['crushedRightHand'],
        'consumablesUsed': [
          {'item': potionItemId, 'quantity': 1},
        ],
        'spellsUsed': [
          {'spell': fireballSpellId, 'usages': 1},
        ],
      });
    });

    test('removing every engine injury sends an empty list (D-14)', () {
      final correction = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(
          hpAfter: 600,
          injuriesAdded: [InjuryType.crushedRightHand],
        ),
      ).withInjuryToggled(InjuryType.crushedRightHand);

      final json = correction.toJson();
      expect(json.containsKey('injuries'), isTrue);
      expect(json['injuries'], isEmpty);
    });

    test('toggling an absent injury adds it (D-06)', () {
      final correction = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(hpAfter: 600),
      ).withInjuryToggled(InjuryType.blackEye);

      expect(correction.injuries, [InjuryType.blackEye]);
    });

    test('a zero usage is not sent (D-06)', () {
      final correction =
          MissionCorrection.fromEffects(
                _aldo,
                const MissionFightEffects(
                  hpAfter: 600,
                  consumablesUsed: [
                    MissionItemUsage(itemId: potionItemId, quantity: 1),
                  ],
                  spellsUsed: [
                    MissionSpellUsage(spellId: fireballSpellId, usages: 1),
                  ],
                ),
              )
              .withConsumableUsed(potionItemId, 0)
              .withSpellUsed(fireballSpellId, 0)
              .withHp(550);

      expect(correction.toJson(), {
        'characterId': _aldo,
        'hpAfter': 550,
        'injuries': <String>[],
        'consumablesUsed': <Object>[],
        'spellsUsed': <Object>[],
      });
    });
  });

  group('fights section from the served draft', () {
    test(
      'fightsInputOf keeps served enemies and served corrections (D-24)',
      () {
        final inputs = fightsInputOf(
          _draft(
            fights: [
              _simulatedFight(
                aldoCorrected: missionEffectsJson(hpAfter: 650),
                beaCorrected: missionEffectsJson(
                  hpAfter: 800,
                  injuriesAdded: const [],
                ),
              ),
              _simulatedFight(enemies: [_bandit()]),
            ],
          ),
        );

        expect(inputs, hasLength(2));
        expect(_fightJson(inputs[0])['enemies'], [
          {'enemy': 'enemy-wolf', 'quantity': 3},
        ]);
        expect(_correctionsOf(inputs[0]), [
          {
            'characterId': _aldo,
            'hpAfter': 650,
            'injuries': ['crushedRightHand'],
            'consumablesUsed': <Object>[],
            'spellsUsed': <Object>[],
          },
          {
            'characterId': _bea,
            'hpAfter': 800,
            'injuries': <String>[],
            'consumablesUsed': <Object>[],
            'spellsUsed': <Object>[],
          },
        ]);
        expect(_fightJson(inputs[1]).containsKey('corrections'), isFalse);
        expect(_fightJson(inputs[1])['enemies'], [
          {'enemy': 'enemy-bandit', 'quantity': 1},
        ]);
      },
    );

    test(
      'fightsInputWithEnemies sends no corrections, the BE keeps the unchanged prefix (D-24)',
      () {
        final draft = _draft(
          fights: [
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 650)),
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 600)),
          ],
        );

        final inputs = fightsInputWithEnemies(draft, [
          [const MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
          [const MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 4)],
          [const MissionEnemyInput(enemyId: 'enemy-bandit', quantity: 1)],
        ]);

        expect(inputs, hasLength(3));
        expect(_fightJson(inputs[0]).containsKey('corrections'), isFalse);
        expect(_fightJson(inputs[1]).containsKey('corrections'), isFalse);
        expect(_fightJson(inputs[1])['enemies'], [
          {'enemy': 'enemy-wolf', 'quantity': 4},
        ]);
        expect(_fightJson(inputs[2]).containsKey('corrections'), isFalse);
      },
    );

    test(
      'changing the enemies of fight 1 sends no corrections for a corrected fight 2 (D-24)',
      () {
        final draft = _draft(
          fights: [
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 650)),
            _simulatedFight(
              enemies: [_bandit()],
              aldoCorrected: missionEffectsJson(hpAfter: 600),
            ),
          ],
        );

        final inputs = fightsInputWithEnemies(draft, [
          [const MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 5)],
          [const MissionEnemyInput(enemyId: 'enemy-bandit', quantity: 1)],
        ]);

        expect(inputs, hasLength(2));
        expect(_fightJson(inputs[1]).containsKey('corrections'), isFalse);
      },
    );

    test('zero fights is an empty fights list (D-24)', () {
      final draft = _draft(fights: [_simulatedFight()]);

      expect(fightsInputOf(_draft()), isEmpty);
      expect(fightsInputWithEnemies(draft, const []), isEmpty);
      expect(
        SaveMissionDraftInput(
          pendingQuestId: 'pq-1',
          fights: fightsInputWithEnemies(draft, const []),
        ).toJson(),
        {'pendingQuestId': 'pq-1', 'fights': <Object>[]},
      );
    });

    test(
      'fightsInputWithCorrections sends corrections for the given fight only (D-06, D-31)',
      () {
        final draft = _draft(
          fights: [
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 650)),
            _simulatedFight(),
          ],
        );

        final inputs = fightsInputWithCorrections(draft, 1, [
          MissionCorrection.fromEffects(
            _aldo,
            const MissionFightEffects(hpAfter: 300),
          ),
        ]);

        expect(_fightJson(inputs[0]).containsKey('corrections'), isFalse);
        expect(_fightJson(inputs[0])['enemies'], [
          {'enemy': 'enemy-wolf', 'quantity': 3},
        ]);
        expect(
          (_correctionsOf(inputs[1]).first as Map<String, dynamic>)['hpAfter'],
          300,
        );
      },
    );

    test(
      'Avanti on fight 1 with fight 2 already corrected sends no corrections for fight 2 (D-24, D-31)',
      () {
        final draft = _draft(
          fights: [
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 650)),
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 600)),
          ],
        );

        final inputs = fightsInputWithCorrections(draft, 0, [
          MissionCorrection.fromEffects(
            _aldo,
            const MissionFightEffects(hpAfter: 500),
          ),
        ]);

        expect(inputs, hasLength(2));
        expect(_correctionsOf(inputs[0]).first, containsPair('hpAfter', 500));
        expect(_fightJson(inputs[1]).containsKey('corrections'), isFalse);
      },
    );

    test(
      'a fight\'s corrections are always the full list with hpAfter for every participant (D-06, BE handoff)',
      () {
        final draft = _draft(
          fights: [
            _simulatedFight(aldoCorrected: missionEffectsJson(hpAfter: 650)),
          ],
        );

        final replaced = fightsInputWithCorrections(draft, 0, [
          MissionCorrection.fromEffects(
            _aldo,
            const MissionFightEffects(hpAfter: 500),
          ),
        ]);
        final served = fightsInputOf(draft);

        for (final inputs in [replaced, served]) {
          final corrections = _correctionsOf(
            inputs.single,
          ).cast<Map<String, dynamic>>();
          expect(corrections.map((c) => c['characterId']), [_aldo, _bea]);
          expect(corrections.every((c) => c.containsKey('hpAfter')), isTrue);
          expect(corrections.last['hpAfter'], 820);
        }
        expect(
          _correctionsOf(replaced.single).first,
          containsPair('hpAfter', 500),
        );
        expect(
          _correctionsOf(served.single).first,
          containsPair('hpAfter', 650),
        );
      },
    );
  });

  group('MissionPrizeInput', () {
    test('a prize input sends free coins and xp (D-15)', () {
      final input = MissionPrizeInput.of(
        _prize(),
      ).withCoins(const Coins(gold: 900)).withXp(12000);
      final negative = input
          .withCoins(const Coins(gold: -3, silver: 5, copper: -1))
          .withXp(-40);

      expect(input.toJson(), {
        'characterId': _aldo,
        'coins': {'gold': 900, 'silver': 0, 'copper': 0},
        'cure': false,
        'items': [
          {'item': potionItemId, 'quantity': 2},
        ],
        'pet': null,
        'spell': null,
        'xp': 12000,
      });
      expect(negative.coins, const Coins(silver: 5));
      expect(negative.xp, 0);
    });

    test('item quantity stays within 1..99 (D-15)', () {
      final input = MissionPrizeInput.of(_prize());

      expect(input.withItemQuantity(potionItemId, 0).items.single.quantity, 1);
      expect(
        input.withItemQuantity(potionItemId, 150).items.single.quantity,
        99,
      );
      final added = input.withItemAdded('e-sword').withItemAdded('e-sword');
      expect(added.items, const [
        MissionPrizeItem(itemId: potionItemId, quantity: 2),
        MissionPrizeItem(itemId: 'e-sword', quantity: 2),
      ]);
      expect(added.withoutItem(potionItemId).items, const [
        MissionPrizeItem(itemId: 'e-sword', quantity: 2),
      ]);
    });

    test(
      'one pet and one spell at most; cure is a kept or removed flag (D-22)',
      () {
        final input = MissionPrizeInput.of(
          _prize(cure: const {'lifePointsShare': 0.5, 'canHeal': <String>[]}),
        );

        expect(input.toJson()['cure'], isTrue);
        expect(input.withoutCure().toJson()['cure'], isFalse);
        expect(input.withoutCure().withCure().toJson()['cure'], isTrue);
        final withPet = input.withPet('pet-owl').withSpell(fireballSpellId);
        expect(withPet.toJson()['pet'], 'pet-owl');
        expect(withPet.toJson()['spell'], fireballSpellId);
        expect(withPet.withPet('pet-cat').toJson()['pet'], 'pet-cat');
        expect(withPet.withPet(null).toJson()['pet'], isNull);
        expect(withPet.withSpell(null).toJson()['spell'], isNull);
      },
    );
  });

  group('operation inputs', () {
    test('save sends only the present sections (D-18)', () {
      expect(
        const SaveMissionDraftInput(
          pendingQuestId: 'pq-1',
          step: MissionDraftStep.fights,
        ).toJson(),
        {'pendingQuestId': 'pq-1', 'step': 'fights'},
      );
      expect(
        const SaveMissionDraftInput(
          pendingQuestId: 'pq-1',
          placeId: 'poi-ruins-1',
        ).toJson(),
        {'pendingQuestId': 'pq-1', 'place': 'poi-ruins-1'},
      );
      expect(
        SaveMissionDraftInput(
          pendingQuestId: 'pq-1',
          prizes: [MissionPrizeInput.of(_prize())],
        ).toJson()['prizes'],
        [MissionPrizeInput.of(_prize()).toJson()],
      );
    });

    test('simulate sends the fight index and its enemies (D-02, D-24)', () {
      expect(
        const SimulateMissionFightInput(
          pendingQuestId: 'pq-1',
          fightIndex: 1,
          enemies: [MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
        ).toJson(),
        {
          'pendingQuestId': 'pq-1',
          'fightIndex': 1,
          'enemies': [
            {'enemy': 'enemy-wolf', 'quantity': 3},
          ],
        },
      );
    });

    test('MissionEnemyInput.of reads the served enemy and quantity', () {
      final served = MissionFight.tryFromJson(
        missionFightJson(enemies: [_wolves(quantity: 5)]),
      )!.enemies.single;

      expect(
        MissionEnemyInput.of(served),
        const MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 5),
      );
    });
  });
}
