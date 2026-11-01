import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson().map(PendingRequest.fromJson).toList(),
).single;

ParticipantDraft _draft(String id, String name) => ParticipantDraft.from(
  Character.fromJson(participantCharacterJson(id: id, name: name)),
  fallbackName: name,
);

final ParticipantDraft _bea = _draft('char-bea', 'Bea');
final ParticipantDraft _cosimo = _draft('char-cosimo', 'Cosimo');

QuestResult _result({
  List<Object?> injuriesAdded = const [],
  int levelAfter = 2,
  String titleAfter = 'rookie',
  Map<String, dynamic>? spellLearned,
  String character = 'char-bea',
}) => QuestResult.fromJson(
  questResultJson(
    character: character,
    outcome: 'gmCompleted',
    hpBefore: 18,
    hpAfter: 5,
    injuriesAdded: injuriesAdded,
    xpGained: 40,
    levelBefore: 2,
    levelAfter: levelAfter,
    titleBefore: 'rookie',
    titleAfter: titleAfter,
    spellLearned: spellLearned,
  ),
);

void main() {
  group('confirmationRecapOf', () {
    test('untouched drafts say that nothing changes', () {
      final recap = confirmationRecapOf(card: _card, drafts: [_bea, _cosimo]);

      expect(recap, contains('L\'assedio di Borgo Rovo'));
      expect(recap, contains('Partecipanti: 2'));
      expect(
        recap,
        contains('Nessuna modifica: i partecipanti restano come sono'),
      );
    });

    test('lists only the changes of the changed participants', () {
      final changed = _bea
          .withHp(5)
          .withInjuryToggled(InjuryType.brokenLeftLeg)
          .withConsumableUsed(potionItemId, 2)
          .withSpellUsed(fireballSpellId, 1);

      final recap = confirmationRecapOf(
        card: _card,
        drafts: [changed, _cosimo],
      );

      expect(recap, contains('Bea: PV 18 → 5'));
      expect(recap, contains('Gamba sinistra rotta'));
      expect(recap, contains('Pozione di cura ×2'));
      expect(recap, contains('Palla di fuoco ×1'));
      expect(recap, isNot(contains('Cosimo')));
      expect(recap, isNot(contains('Nessuna modifica')));
    });

    test('an unchanged HP is not listed', () {
      final recap = confirmationRecapOf(
        card: _card,
        drafts: [_bea.withInjuryToggled(InjuryType.brokenLeftLeg), _cosimo],
      );

      expect(recap, contains('Bea'));
      expect(recap, isNot(contains('PV')));
    });
  });

  group('resultRecapLinesOf', () {
    test('a plain result lists outcome, HP and XP only', () {
      expect(resultRecapLinesOf(_result()), [
        'Missione completata',
        'PV 18 → 5',
        '+40 XP',
      ]);
    });

    test('injuries, level, title and spell appear only when present', () {
      final lines = resultRecapLinesOf(
        _result(
          injuriesAdded: const ['brokenLeftLeg'],
          levelAfter: 3,
          titleAfter: 'adventurer',
          spellLearned: const {'id': 'spell-ice', 'name': 'Lancia di ghiaccio'},
        ),
      );

      expect(lines, [
        'Missione completata',
        'PV 18 → 5',
        'Ferite: Gamba sinistra rotta',
        '+40 XP',
        'Livello 2 → 3',
        'Titolo: Recluta → Avventuriero',
        'Magia appresa: Lancia di ghiaccio',
      ]);
    });
  });

  group('recapNameOf', () {
    test('matches the participant on the card', () {
      expect(recapNameOf(_result(), _card), 'Bea');
    });

    test('falls back to «Personaggio»', () {
      expect(recapNameOf(_result(character: 'char-x'), _card), 'Personaggio');
    });
  });
}
