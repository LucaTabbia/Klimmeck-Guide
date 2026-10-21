import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/utils/stable_notification_id.dart';

void main() {
  const characterId = '6712a0c4e1b2c3d4e5f60718';

  Map<String, Object?> travelEndData() => {
    'type': 'travelEnd',
    'title': 'Viaggio completato',
    'body': 'Il tuo personaggio è arrivato a destinazione.',
    'sentAt': '2026-10-18T12:00:00.000Z',
    'id': characterId,
  };

  Map<String, Object?> streamerLiveData({
    String sentAt = '2026-10-18T12:00:42.123Z',
  }) => {
    'type': 'streamerLive',
    'title': 'Lo streamer è in live',
    'body': 'Unisciti alla diretta.',
    'sentAt': sentAt,
  };

  group('tryParse', () {
    test('parses a personal event and keeps its id', () {
      final event = PushEvent.tryParse(travelEndData());

      expect(event?.category, NotificationCategory.travelEnd);
      expect(event?.title, 'Viaggio completato');
      expect(event?.body, 'Il tuo personaggio è arrivato a destinazione.');
      expect(event?.id, characterId);
      expect(event?.sentAt, DateTime.utc(2026, 10, 18, 12));
    });

    test('keeps the id of a quest end', () {
      final event = PushEvent.tryParse({
        ...travelEndData(),
        'type': 'questEnd',
        'id': 'q-1',
      });

      expect(event?.category, NotificationCategory.questEnd);
      expect(event?.id, 'q-1');
    });

    test('drops an id sent with a streamer live broadcast', () {
      final event = PushEvent.tryParse({...streamerLiveData(), 'id': 'x'});

      expect(event?.category, NotificationCategory.streamerLive);
      expect(event?.id, isNull);
    });

    test('drops an id outside the allowed alphabet', () {
      final event = PushEvent.tryParse({...travelEndData(), 'id': '../x y'});

      expect(event, isNotNull);
      expect(event?.id, isNull);
    });

    final malformed = <String, Map<String, Object?>>{
      'missing title': {...travelEndData()}..remove('title'),
      'empty title': {...travelEndData(), 'title': ''},
      'missing body': {...travelEndData()}..remove('body'),
      'empty body': {...travelEndData(), 'body': ''},
      'missing sentAt': {...travelEndData()}..remove('sentAt'),
      'unparseable sentAt': {...travelEndData(), 'sentAt': 'yesterday'},
      'unknown type': {...travelEndData(), 'type': 'combatResult'},
      'missing type': {...travelEndData()}..remove('type'),
      'non-string title': {...travelEndData(), 'title': 42},
      'non-string sentAt': {...travelEndData(), 'sentAt': 1760788800000},
    };

    malformed.forEach((description, data) {
      test('returns null for $description', () {
        expect(PushEvent.tryParse(data), isNull);
      });
    });
  });

  group('dedupKey', () {
    test('is type and id for a personal event', () {
      expect(
        PushEvent.tryParse(travelEndData())?.dedupKey,
        'travelEnd|$characterId',
      );
    });

    test('is type and UTC minute of sentAt for a broadcast', () {
      expect(
        PushEvent.tryParse(streamerLiveData())?.dedupKey,
        'streamerLive|2026-10-18T12:00:00.000Z',
      );
    });

    test('normalises a non-UTC sentAt to the UTC minute', () {
      expect(
        PushEvent.tryParse(
          streamerLiveData(sentAt: '2026-10-18T14:00:42.123+02:00'),
        )?.dedupKey,
        'streamerLive|2026-10-18T12:00:00.000Z',
      );
    });

    test(
      'falls back to the minute for a personal event without a valid id',
      () {
        final event = PushEvent.tryParse({...travelEndData()}..remove('id'));

        expect(event?.dedupKey, 'travelEnd|2026-10-18T12:00:00.000Z');
      },
    );
  });

  group('notificationId', () {
    test('is the stable id of the dedup key', () {
      final event = PushEvent.tryParse(travelEndData())!;

      expect(event.notificationId, stableNotificationId(event.dedupKey));
    });

    test('is the same for two parses of the same message', () {
      expect(
        PushEvent.tryParse(travelEndData())?.notificationId,
        PushEvent.tryParse(travelEndData())?.notificationId,
      );
    });
  });

  test('exposes the tap intent of the event', () {
    expect(
      PushEvent.tryParse(travelEndData())?.intent,
      NotificationIntent(
        category: NotificationCategory.travelEnd,
        id: characterId,
        sentAt: DateTime.utc(2026, 10, 18, 12),
      ),
    );
  });

  test('exposes the banner content of the event', () {
    expect(
      PushEvent.tryParse(travelEndData())?.notification,
      const KGNotification(
        title: 'Viaggio completato',
        description: 'Il tuo personaggio è arrivato a destinazione.',
      ),
    );
  });
}
