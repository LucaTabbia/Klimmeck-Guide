import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';
import 'package:klimmeck_guide/models/quest/quest_blocked_reason.dart';

void main() {
  test('available has no blocked reason', () {
    expect(questBlockedReasonOf(QuestAvailability.available), isNull);
  });

  test('every other availability has a non-empty reason', () {
    for (final availability in QuestAvailability.values) {
      if (availability == QuestAvailability.available) continue;
      final reason = questBlockedReasonOf(availability);
      expect(reason, isNotNull, reason: availability.name);
      expect(reason, isNotEmpty, reason: availability.name);
    }
  });

  test('title mismatch never names the title: the badge is on the sheet', () {
    expect(
      questBlockedReasonOf(QuestAvailability.titleMismatch),
      'Il tuo titolo non permette questa missione',
    );
  });

  test('prison explains itself in the world (quick 261110-cgd)', () {
    expect(
      questBlockedReasonOf(QuestAvailability.imprisoned),
      'Sei in prigione',
    );
  });

  test('a heal with no effect explains itself in the world (D-20)', () {
    expect(
      questBlockedReasonOf(QuestAvailability.noEffect),
      'Il tempio non può fare nulla per te adesso',
    );
  });

  test('a quest awaiting its rescue explains itself in the world '
      '(quick 261113-aql)', () {
    expect(
      questBlockedReasonOf(QuestAvailability.awaitingRescue),
      'Soccorso in corso: la missione riapre quando il soccorso si conclude.',
    );
  });

  test("a mission in progress prints «Missione in corso: aspetta l'esito» "
      '(D-30)', () {
    expect(
      questBlockedReasonOf(QuestAvailability.missionInProgress),
      "Missione in corso: aspetta l'esito",
    );
  });
}
