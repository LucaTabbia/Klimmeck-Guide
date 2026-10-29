import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';

ParticipantDraft draftOf({
  int? currentLifePoints = 18,
  int maxLifePoints = 25,
}) => ParticipantDraft.from(
  Character.fromJson(
    participantCharacterJson(
      currentLifePoints: currentLifePoints,
      maxLifePoints: maxLifePoints,
    ),
  ),
  fallbackName: 'Aldo',
);

void main() {
  group('ParticipantDraft.from', () {
    test('starts at «no change» from the character read', () {
      final draft = draftOf();

      expect(draft.characterId, 'char-aldo');
      expect(draft.name, 'Aldo');
      expect(draft.currentLifePoints, 18);
      expect(draft.maxLifePoints, 25);
      expect(draft.hpAfter, 18);
      expect(draft.existingInjuries, [InjuryType.blackEye]);
      expect(draft.addedInjuries, isEmpty);
      expect(draft.consumables, [
        const ConsumableLine(
          itemId: potionItemId,
          name: 'Pozione di cura',
          owned: 3,
          used: 0,
        ),
      ]);
      expect(draft.spells, [
        const SpellLine(
          spellId: fireballSpellId,
          name: 'Palla di fuoco',
          remaining: 2,
          used: 0,
        ),
      ]);
    });

    test('a current HP above the max starts at the max', () {
      expect(draftOf(currentLifePoints: 30).hpAfter, 25);
    });

    test('a missing current HP starts at the max', () {
      expect(draftOf(currentLifePoints: null).hpAfter, 25);
    });

    test('the HP cannot be edited with a max of 1', () {
      expect(
        draftOf(currentLifePoints: 1, maxLifePoints: 1).canEditHp,
        isFalse,
      );
      expect(draftOf().canEditHp, isTrue);
    });

    test('the name falls back when the character has none', () {
      final draft = ParticipantDraft.from(
        Character.fromJson({'id': 'char-x'}),
        fallbackName: 'Senza nome',
      );

      expect(draft.name, 'Senza nome');
      expect(draft.maxLifePoints, 1);
      expect(draft.hpAfter, 1);
      expect(draft.consumables, isEmpty);
      expect(draft.spells, isEmpty);
    });
  });

  group('edits', () {
    test('withHp clamps to 1..max', () {
      expect(draftOf().withHp(0).hpAfter, 1);
      expect(draftOf().withHp(99).hpAfter, 25);
      expect(draftOf().withHp(10).hpAfter, 10);
    });

    test('withInjuryToggled ignores an existing injury', () {
      final draft = draftOf().withInjuryToggled(InjuryType.blackEye);

      expect(draft.addedInjuries, isEmpty);
      expect(draft, draftOf());
    });

    test('withInjuryToggled adds then removes a new injury', () {
      final added = draftOf().withInjuryToggled(InjuryType.brokenLeftArm);

      expect(added.addedInjuries, [InjuryType.brokenLeftArm]);
      expect(
        added.withInjuryToggled(InjuryType.brokenLeftArm).addedInjuries,
        isEmpty,
      );
    });

    test('added injuries follow the InjuryType order', () {
      final lastInjury = InjuryType.values.last;
      final draft = draftOf()
          .withInjuryToggled(lastInjury)
          .withInjuryToggled(InjuryType.brokenLeftArm);

      expect(draft.addedInjuries, [InjuryType.brokenLeftArm, lastInjury]);
    });

    test('withConsumableUsed clamps to 0..owned and ignores unknown ids', () {
      expect(
        draftOf().withConsumableUsed(potionItemId, 5).consumables.single.used,
        3,
      );
      expect(
        draftOf().withConsumableUsed(potionItemId, -1).consumables.single.used,
        0,
      );
      expect(draftOf().withConsumableUsed('loot-unknown', 2), draftOf());
    });

    test('withSpellUsed clamps to 0..remaining', () {
      expect(draftOf().withSpellUsed(fireballSpellId, 9).spells.single.used, 2);
      expect(
        draftOf().withSpellUsed(fireballSpellId, -3).spells.single.used,
        0,
      );
      expect(draftOf().withSpellUsed('spell-unknown', 1), draftOf());
    });
  });

  group('override', () {
    test('an untouched draft has no override', () {
      expect(draftOf().override, isNull);
    });

    test('an HP equal to the current one is no change', () {
      expect(draftOf().withHp(18).override, isNull);
    });

    test('a used quantity back at 0 is no change', () {
      expect(
        draftOf()
            .withConsumableUsed(potionItemId, 2)
            .withConsumableUsed(potionItemId, 0)
            .override,
        isNull,
      );
    });

    test('carries only what the GM changed', () {
      final override = draftOf()
          .withHp(10)
          .withInjuryToggled(InjuryType.brokenLeftArm)
          .withConsumableUsed(potionItemId, 2)
          .withSpellUsed(fireballSpellId, 1)
          .override!;

      expect(override.toJson(), {
        'characterId': 'char-aldo',
        'hpAfter': 10,
        'injuries': ['brokenLeftArm'],
        'consumablesUsed': [
          {'item': potionItemId, 'quantity': 2},
        ],
        'spellsUsed': [
          {'spell': fireballSpellId, 'usages': 1},
        ],
      });
    });

    test('an injury-only override has only characterId and injuries', () {
      final json = draftOf()
          .withInjuryToggled(InjuryType.brokenLeftArm)
          .override!
          .toJson();

      expect(json.keys, unorderedEquals(['characterId', 'injuries']));
    });
  });

  test('overridesOf keeps only the changed drafts', () {
    final changed = draftOf().withHp(10);

    expect(overridesOf([draftOf(), changed]), [changed.override]);
  });
}
