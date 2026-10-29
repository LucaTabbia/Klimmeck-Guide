import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  test('fromJson reads quest, aid quest and a UTC since', () {
    final aid = AwaitingAid.fromJson(awaitingAidJson());

    expect(aid.questId, 'q-1');
    expect(aid.aidQuestId, 'aid-1');
    expect(aid.since, DateTime.utc(2026, 10, 27, 11));
    expect(aid.since.isUtc, isTrue);
  });

  test('a non-UTC since is normalised to UTC', () {
    final aid = AwaitingAid.fromJson(
      awaitingAidJson(since: '2026-10-27T13:00:00.000+02:00'),
    );

    expect(aid.since, DateTime.utc(2026, 10, 27, 11));
    expect(aid.since.isUtc, isTrue);
  });

  test('toJson round trips with a UTC since', () {
    final aid = AwaitingAid.fromJson(awaitingAidJson());

    expect(AwaitingAid.fromJson(aid.toJson()), aid);
    expect(aid.toJson()['since'] as String, endsWith('Z'));
  });

  group('tryFromJson', () {
    test('parses a valid map', () {
      expect(
        AwaitingAid.tryFromJson(awaitingAidJson()),
        AwaitingAid.fromJson(awaitingAidJson()),
      );
    });

    final malformed = <String, Object?>{
      'null': null,
      'a string': 'broken',
      'a map without aidQuest': {
        'quest': 'q-1',
        'since': '2026-10-27T11:00:00.000Z',
      },
      'an unparsable since': awaitingAidJson(since: 'x'),
    };

    malformed.forEach((label, json) {
      test('returns null for $label', () {
        expect(AwaitingAid.tryFromJson(json), isNull);
      });
    });
  });
}
