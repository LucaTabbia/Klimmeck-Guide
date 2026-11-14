import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson().map(PendingRequest.fromJson).toList(),
).single;

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
