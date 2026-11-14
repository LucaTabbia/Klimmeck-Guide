import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/quest_companion_outcome.dart';

import '../../helpers/fixtures/quest_result_fixtures.dart';

void main() {
  test('reads the served companion entry (D-27)', () {
    final companion = QuestCompanionOutcome.tryFromJson(companionOutcomeJson());

    expect(
      companion,
      const QuestCompanionOutcome(
        name: 'Fenrir',
        lifeBefore: 300,
        lifePoints: 120,
        maxLifePoints: 300,
      ),
    );
    expect(companion!.isDefeated, isFalse);
    expect(companion.fullLifeAt, isNull);
  });

  test('a malformed entry reads null (D-27)', () {
    final malformed = <Object?>[
      companionOutcomeJson()..remove('name'),
      companionOutcomeJson(name: '   '),
      companionOutcomeJson()..['name'] = 7,
      companionOutcomeJson()..['lifePoints'] = '5',
      companionOutcomeJson()..remove('lifeBefore'),
      companionOutcomeJson()..['maxLifePoints'] = null,
      'Fenrir',
      null,
      <Object?>[],
    ];

    for (final json in malformed) {
      expect(QuestCompanionOutcome.tryFromJson(json), isNull, reason: '$json');
    }
  });

  test('defeated is read leniently and fullLifeAt in UTC (D-27)', () {
    final defeated = QuestCompanionOutcome.tryFromJson(
      companionOutcomeJson(
        lifePoints: 0,
        defeated: true,
        fullLifeAt: '2026-10-27T23:00:00.000+01:00',
      ),
    )!;

    expect(defeated.isDefeated, isTrue);
    expect(defeated.fullLifeAt, DateTime.utc(2026, 10, 27, 22));
    expect(defeated.fullLifeAt!.isUtc, isTrue);

    for (final flag in <Object?>['true', 1, null]) {
      final json = companionOutcomeJson()..['defeated'] = flag;

      expect(
        QuestCompanionOutcome.tryFromJson(json)!.isDefeated,
        isFalse,
        reason: '$flag',
      );
    }

    for (final date in <Object?>['not a date', 12, true]) {
      final json = companionOutcomeJson()..['fullLifeAt'] = date;

      expect(
        QuestCompanionOutcome.tryFromJson(json)!.fullLifeAt,
        isNull,
        reason: '$date',
      );
    }
  });

  test('toJson round trip (D-27)', () {
    final served = [
      companionOutcomeJson(),
      companionOutcomeJson(
        lifePoints: 0,
        defeated: true,
        fullLifeAt: '2026-10-27T22:00:00.000Z',
      ),
    ];

    for (final json in served) {
      final companion = QuestCompanionOutcome.tryFromJson(json)!;

      expect(QuestCompanionOutcome.tryFromJson(companion.toJson()), companion);
    }
  });
}
