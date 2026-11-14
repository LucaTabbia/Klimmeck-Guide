import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';
import 'package:klimmeck_guide/models/quest/quest_blocked_reason.dart';

void main() {
  test('available has no blocked reason', () {
    expect(
      questBlockedReasonOf(
        QuestAvailability.available,
        minTitle: null,
        type: QuestType.hunt,
      ),
      isNull,
    );
  });

  test('every other availability has a non-empty reason', () {
    for (final availability in QuestAvailability.values) {
      if (availability == QuestAvailability.available) continue;
      final reason = questBlockedReasonOf(
        availability,
        minTitle: null,
        type: QuestType.hunt,
      );
      expect(reason, isNotNull, reason: availability.name);
      expect(reason, isNotEmpty, reason: availability.name);
    }
  });

  test('title mismatch names the title, exact for story', () {
    expect(
      questBlockedReasonOf(
        QuestAvailability.titleMismatch,
        minTitle: TitleType.paladin,
        type: QuestType.story,
      ),
      'Serve il titolo Paladino',
    );
    expect(
      questBlockedReasonOf(
        QuestAvailability.titleMismatch,
        minTitle: TitleType.hero,
        type: QuestType.boss,
      ),
      'Serve almeno il titolo Eroe',
    );
  });

  test('prison explains itself in the world (quick 261110-cgd)', () {
    expect(
      questBlockedReasonOf(
        QuestAvailability.imprisoned,
        minTitle: null,
        type: QuestType.crime,
      ),
      'Sei in prigione',
    );
  });

  test('a heal with no effect explains itself in the world (D-20)', () {
    expect(
      questBlockedReasonOf(
        QuestAvailability.noEffect,
        minTitle: null,
        type: QuestType.heal,
      ),
      'Il tempio non può fare nulla per te adesso',
    );
  });

  test('a quest awaiting its rescue explains itself in the world '
      '(quick 261113-aql)', () {
    for (final type in [QuestType.hunt, QuestType.dungeon]) {
      expect(
        questBlockedReasonOf(
          QuestAvailability.awaitingRescue,
          minTitle: null,
          type: type,
        ),
        'Soccorso in corso: la missione riapre quando il soccorso si conclude.',
      );
    }
  });

  test("a mission in progress prints «Missione in corso: aspetta l'esito» "
      '(D-30)', () {
    for (final type in [QuestType.hunt, QuestType.story]) {
      expect(
        questBlockedReasonOf(
          QuestAvailability.missionInProgress,
          minTitle: null,
          type: type,
        ),
        "Missione in corso: aspetta l'esito",
      );
    }
  });
}
