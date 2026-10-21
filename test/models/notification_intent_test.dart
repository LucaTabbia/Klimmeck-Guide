import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';

void main() {
  final sentAt = DateTime.utc(2026, 10, 18, 12);

  group('toPayload / tryFromPayload', () {
    test('round-trips a personal intent with its id', () {
      final intent = NotificationIntent(
        category: NotificationCategory.questEnd,
        id: 'q-1',
        sentAt: sentAt,
      );

      final payload = intent.toPayload();

      expect(
        payload,
        '{"type":"questEnd","id":"q-1","sentAt":"2026-10-18T12:00:00.000Z"}',
      );
      expect(NotificationIntent.tryFromPayload(payload), intent);
    });

    test('round-trips a broadcast intent without an id key', () {
      final intent = NotificationIntent(
        category: NotificationCategory.streamerLive,
        sentAt: sentAt,
      );

      final payload = intent.toPayload();

      expect(payload, isNot(contains('"id"')));
      final parsed = NotificationIntent.tryFromPayload(payload);
      expect(parsed, intent);
      expect(parsed?.id, isNull);
    });
  });

  group('tryFromPayload rejects malformed payloads', () {
    const malformed = <String?>[
      null,
      '',
      'not json',
      '[]',
      '{"type":"combatResult","sentAt":"2026-10-18T12:00:00.000Z"}',
      '{"type":"questEnd"}',
      '{"type":"questEnd","sentAt":"nope"}',
    ];

    for (final payload in malformed) {
      test('returns null for $payload', () {
        expect(NotificationIntent.tryFromPayload(payload), isNull);
      });
    }
  });

  group('tryFromPayload drops an invalid id', () {
    for (final id in ['../x y', 'a' * 129]) {
      test('keeps the intent without the id "$id"', () {
        final payload =
            '{"type":"travelEnd","id":"$id",'
            '"sentAt":"2026-10-18T12:00:00.000Z"}';

        final intent = NotificationIntent.tryFromPayload(payload);

        expect(
          intent,
          NotificationIntent(
            category: NotificationCategory.travelEnd,
            sentAt: sentAt,
          ),
        );
      });
    }
  });
}
