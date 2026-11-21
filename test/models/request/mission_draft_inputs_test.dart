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

  group('wound removals of a correction (Phase 24)', () {
    const carried = InjuryType.blackEye;

    MissionCorrection correctionOf({
      List<InjuryType> injuriesAdded = const [],
      List<InjuryType> injuriesRemoved = const [],
    }) => MissionCorrection.fromEffects(
      _aldo,
      MissionFightEffects(
        hpAfter: 600,
        injuriesAdded: injuriesAdded,
        injuriesRemoved: injuriesRemoved,
      ),
    );

    test('fromEffects seeds the removed wounds from the served effect '
        '(D-13)', () {
      final correction = correctionOf(injuriesRemoved: const [carried]);

      expect(correction.injuriesRemoved, [carried]);
      expect(correction.declaresRemovals, isFalse);
    });

    test('toggling a removal adds the wound to the removed ones (D-13)', () {
      final correction = correctionOf().withInjuryRemovalToggled(carried);

      expect(correction.injuriesRemoved, [carried]);
      expect(correction.injuries, isEmpty);
    });

    test('un-removing a wound drops it from the added ones too (D-16)', () {
      final correction = correctionOf(
        injuriesAdded: const [carried],
        injuriesRemoved: const [carried],
      ).withInjuryRemovalToggled(carried);

      expect(correction.injuriesRemoved, isEmpty);
      expect(correction.injuries, isEmpty);
    });

    test('un-removing a wound keeps the other added ones (D-16)', () {
      final correction = correctionOf(
        injuriesAdded: const [InjuryType.crushedRightHand, carried],
        injuriesRemoved: const [carried, InjuryType.brokenLeftArm],
      ).withInjuryRemovalToggled(carried);

      expect(correction.injuriesRemoved, [InjuryType.brokenLeftArm]);
      expect(correction.injuries, [InjuryType.crushedRightHand]);
    });

    test('a removed wound can be added again in the same correction '
        '(D-16)', () {
      final correction = correctionOf()
          .withInjuryRemovalToggled(carried)
          .withInjuryToggled(carried);

      expect(correction.injuriesRemoved, [carried]);
      expect(correction.injuries, [carried]);
      expect(correction.toJson()['injuries'], ['blackEye']);
      expect(correction.toJson()['injuriesRemoved'], ['blackEye']);
    });

    test('toJson omits injuriesRemoved when nothing is removed and the '
        'removals are not declared', () {
      final json = correctionOf(
        injuriesAdded: const [InjuryType.crushedRightHand],
      ).toJson();

      expect(json.containsKey('injuriesRemoved'), isFalse);
    });

    test('a correction that declares its removals sends the list even when '
        'empty (Q7)', () {
      final declared = correctionOf().withRemovalsDeclared();

      expect(declared.declaresRemovals, isTrue);
      expect(declared.toJson()['injuriesRemoved'], <String>[]);
      expect(
        declared.withHp(500).toJson().containsKey('injuriesRemoved'),
        isTrue,
      );
    });

    test('toJson sends the removed wounds by name (D-13)', () {
      final json = correctionOf()
          .withInjuryRemovalToggled(carried)
          .withInjuryRemovalToggled(InjuryType.brokenLeftArm)
          .toJson();

      expect(json['injuriesRemoved'], ['blackEye', 'brokenLeftArm']);
    });

    test('the other corrections keep the removals (D-13)', () {
      final correction = correctionOf(injuriesRemoved: const [carried])
          .withRemovalsDeclared()
          .withHp(500)
          .withInjuryToggled(InjuryType.crushedRightHand)
          .withConsumableUsed(potionItemId, 1);

      expect(correction.injuriesRemoved, [carried]);
      expect(correction.declaresRemovals, isTrue);
    });

    test('equality includes the removals and their declaration', () {
      final plain = correctionOf();

      expect(plain.withInjuryRemovalToggled(carried), isNot(plain));
      expect(plain.withRemovalsDeclared(), isNot(plain));
      expect(correctionOf(), plain);
    });

    test('fightsInputWithCorrections declares the removals of every '
        'correction of the fight when asked, and of none by default '
        '(Q7)', () {
      final draft = _draft(fights: [_simulatedFight(), _simulatedFight()]);
      final given = [
        MissionCorrection.fromEffects(
          _aldo,
          const MissionFightEffects(hpAfter: 500),
        ),
      ];

      final declared = fightsInputWithCorrections(
        draft,
        0,
        given,
        declaresRemovals: true,
      );
      final byDefault = fightsInputWithCorrections(draft, 0, given);

      final declaredCorrections = _correctionsOf(
        declared[0],
      ).cast<Map<String, dynamic>>();
      expect(declaredCorrections.map((c) => c['characterId']), [_aldo, _bea]);
      expect(
        declaredCorrections.map((c) => c['injuriesRemoved']),
        everyElement(<String>[]),
      );
      expect(_fightJson(declared[1]).containsKey('corrections'), isFalse);
      expect(
        _correctionsOf(byDefault[0]).cast<Map<String, dynamic>>().any(
          (c) => c.containsKey('injuriesRemoved'),
        ),
        isFalse,
      );
    });
  });

  group('story additions on the save (Phase 24)', () {
    test('the save input sends the additions only when the section is '
        'present (D-05)', () {
      const absent = SaveMissionDraftInput(
        pendingQuestId: 'pq-1',
        step: MissionDraftStep.stories,
      );
      const present = SaveMissionDraftInput(
        pendingQuestId: 'pq-1',
        backgroundAdditions: [
          MissionBackgroundAdditionInput(
            characterId: _aldo,
            text: 'Ha visto il drago.',
          ),
        ],
      );
      const empty = SaveMissionDraftInput(
        pendingQuestId: 'pq-1',
        backgroundAdditions: [],
      );

      expect(absent.toJson(), {'pendingQuestId': 'pq-1', 'step': 'stories'});
      expect(present.toJson(), {
        'pendingQuestId': 'pq-1',
        'backgroundAdditions': [
          {'characterId': _aldo, 'text': 'Ha visto il drago.'},
        ],
      });
      expect(empty.toJson()['backgroundAdditions'], isEmpty);
      expect(present, isNot(absent));
    });

    test('backgroundAdditionsInputOf builds one entry per participant with '
        'the trimmed text, empty ones included (D-06)', () {
      final additions = backgroundAdditionsInputOf(_draft().participants, {
        _aldo: '  Ha visto il drago.  ',
      });

      expect(additions, const [
        MissionBackgroundAdditionInput(
          characterId: _aldo,
          text: 'Ha visto il drago.',
        ),
        MissionBackgroundAdditionInput(characterId: _bea, text: ''),
      ]);
    });

    test('backgroundAdditionsInputOf ignores the text of a stranger and '
        'sends a blank text as empty (D-06)', () {
      final additions = backgroundAdditionsInputOf(_draft().participants, {
        _bea: '   ',
        'char-ghost': 'Non esiste.',
      });

      expect(additions.map((addition) => addition.toJson()), [
        {'characterId': _aldo, 'text': ''},
        {'characterId': _bea, 'text': ''},
      ]);
    });
  });

  group('companion life correction', () {
    test('fromEffects copies the companion life (D-17)', () {
      final correction = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(hpAfter: 600, companionLifeAfter: 120),
      );

      expect(correction.companionLifeAfter, 120);
      expect(correction.toJson()['companionLifeAfter'], 120);
    });

    test('withCompanionLife changes only the companion life (D-17)', () {
      final served = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(
          hpAfter: 600,
          injuriesAdded: [InjuryType.crushedRightHand],
          companionLifeAfter: 120,
        ),
      );

      final corrected = served.withCompanionLife(1);

      expect(corrected.companionLifeAfter, 1);
      expect(corrected.hpAfter, 600);
      expect(corrected.injuries, [InjuryType.crushedRightHand]);
      expect(corrected, isNot(served));
    });

    test('other corrections keep the companion life (D-17)', () {
      final corrected =
          MissionCorrection.fromEffects(
                _aldo,
                const MissionFightEffects(hpAfter: 600, companionLifeAfter: 90),
              )
              .withHp(500)
              .withInjuryToggled(InjuryType.blackEye)
              .withConsumableUsed(potionItemId, 1)
              .withSpellUsed(fireballSpellId, 1);

      expect(corrected.companionLifeAfter, 90);
    });

    test('toJson sends companionLifeAfter only when set (D-33, Pitfall 1)', () {
      final withoutCompanion = MissionCorrection.fromEffects(
        _aldo,
        const MissionFightEffects(hpAfter: 600),
      );

      expect(withoutCompanion.companionLifeAfter, isNull);
      expect(
        withoutCompanion.toJson().containsKey('companionLifeAfter'),
        isFalse,
      );
      expect(
        withoutCompanion.withCompanionLife(42).toJson()['companionLifeAfter'],
        42,
      );
    });
  });

  group('fights section from the served draft', () {
    test(
      'fightsInputWithEnemies sends no corrections, the BE keeps the unchanged prefix (D-24)',
      () {
        final inputs = fightsInputWithEnemies([
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

    test('zero fights is an empty fights list (D-24)', () {
      expect(fightsInputWithEnemies(const []), isEmpty);
      expect(
        SaveMissionDraftInput(
          pendingQuestId: 'pq-1',
          fights: fightsInputWithEnemies(const []),
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
        final corrections = _correctionsOf(
          replaced.single,
        ).cast<Map<String, dynamic>>();

        expect(corrections.map((c) => c['characterId']), [_aldo, _bea]);
        expect(corrections.every((c) => c.containsKey('hpAfter')), isTrue);
        expect(corrections.first['hpAfter'], 500);
        expect(corrections.last['hpAfter'], 820);
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
