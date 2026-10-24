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
}
