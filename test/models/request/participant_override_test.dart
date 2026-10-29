import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/participant_override.dart';

void main() {
  group('ParticipantOverride.toJson', () {
    test('omits every field left empty', () {
      expect(const ParticipantOverride(characterId: 'char-aldo').toJson(), {
        'characterId': 'char-aldo',
      });
    });

    test('writes injuries by their wire names and usages as inputs', () {
      const override = ParticipantOverride(
        characterId: 'char-aldo',
        hpAfter: 7,
        injuries: [InjuryType.blackEye, InjuryType.brokenLeftArm],
        consumablesUsed: {'loot-potion': 1},
        spellsUsed: {'spell-fireball': 2},
      );

      expect(override.toJson(), {
        'characterId': 'char-aldo',
        'hpAfter': 7,
        'injuries': ['blackEye', 'brokenLeftArm'],
        'consumablesUsed': [
          {'item': 'loot-potion', 'quantity': 1},
        ],
        'spellsUsed': [
          {'spell': 'spell-fireball', 'usages': 2},
        ],
      });
    });

    test('is equal by value', () {
      expect(
        const ParticipantOverride(characterId: 'char-aldo', hpAfter: 3),
        const ParticipantOverride(characterId: 'char-aldo', hpAfter: 3),
      );
    });
  });

  group('CompletePendingRequestInput.toJson', () {
    test('omits outcomes when nobody changed', () {
      expect(
        const CompletePendingRequestInput(
          pendingQuestId: 'pq-1',
          outcomes: [],
        ).toJson(),
        {'pendingQuestId': 'pq-1'},
      );
    });

    test('carries the overrides of the changed participants', () {
      const override = ParticipantOverride(
        characterId: 'char-aldo',
        hpAfter: 5,
      );

      expect(
        const CompletePendingRequestInput(
          pendingQuestId: 'pq-1',
          outcomes: [override],
        ).toJson(),
        {
          'pendingQuestId': 'pq-1',
          'outcomes': [
            {'characterId': 'char-aldo', 'hpAfter': 5},
          ],
        },
      );
    });
  });
}
