import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/data_message_handler.dart';

import '../../../helpers/fakes/in_memory_active_user_store.dart';
import '../../../helpers/fakes/in_memory_notification_preferences_store.dart';
import '../../../helpers/fakes/recording_local_notifications_port.dart';

void main() {
  const travelEndData = <String, Object?>{
    'type': 'travelEnd',
    'title': 'Viaggio completato',
    'body': 'Il tuo personaggio è arrivato a destinazione.',
    'sentAt': '2026-10-18T12:00:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60718',
  };
  const questEndData = <String, Object?>{
    'type': 'questEnd',
    'title': 'Quest completata',
    'body': 'La tua quest si è conclusa.',
    'sentAt': '2026-10-18T12:05:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60719',
  };
  const streamerLiveData = <String, Object?>{
    'type': 'streamerLive',
    'title': 'Lo streamer è in live',
    'body': 'Unisciti alla diretta.',
    'sentAt': '2026-10-18T12:00:42.123Z',
  };
  const ambushDefeatData = <String, Object?>{
    'type': 'ambushDefeat',
    'title': 'Imboscata!',
    'body': 'Sei stato sconfitto: la via torna verso Bosa',
    'sentAt': '2026-10-18T12:10:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60718',
  };

  const prisonReleaseData = <String, Object?>{
    'type': 'prisonRelease',
    'title': 'Di nuovo libero',
    'body': "La prigionia è finita: torna all'avventura.",
    'sentAt': '2026-11-10T12:10:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60718',
  };

  const missionStartData = <String, Object?>{
    'type': 'missionStart',
    'title': 'La missione comincia',
    'body': "L'oste ha dato inizio a «La corte del re»",
    'sentAt': '2026-11-14T12:10:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60718',
  };

  late InMemoryActiveUserStore activeUser;
  late InMemoryNotificationPreferencesStore preferences;
  late RecordingLocalNotificationsPort notifier;

  setUp(() {
    activeUser = InMemoryActiveUserStore()..userId = 'u-1';
    preferences = InMemoryNotificationPreferencesStore();
    notifier = RecordingLocalNotificationsPort();
  });

  Future<void> handle(Map<String, Object?> data) => handleDataMessage(
    data,
    activeUser: activeUser,
    preferences: preferences,
    notifier: notifier,
  );

  void disable(String userId, NotificationCategory category) =>
      preferences.values[InMemoryNotificationPreferencesStore.keyOf(
            userId,
            category,
          )] =
          false;

  group('handleDataMessage', () {
    for (final data in [
      travelEndData,
      questEndData,
      streamerLiveData,
      ambushDefeatData,
      prisonReleaseData,
      missionStartData,
    ]) {
      test('shows one notification for ${data['type']} by default', () async {
        await handle(data);

        expect(notifier.shown, [PushEvent.tryParse(data)]);
      });
    }

    test('shows the ambush defeat with the backend title and body '
        '(D-02, D-10)', () async {
      await handle(ambushDefeatData);

      expect(notifier.shown, hasLength(1));
      expect(notifier.shown.single.title, 'Imboscata!');
      expect(
        notifier.shown.single.body,
        'Sei stato sconfitto: la via torna verso Bosa',
      );
    });

    test('shows nothing without an active user and reads no toggle', () async {
      activeUser.userId = null;

      await handle(travelEndData);

      expect(notifier.shown, isEmpty);
      expect(preferences.reads, 0);
    });

    test('shows nothing when the category toggle is off', () async {
      disable('u-1', NotificationCategory.travelEnd);

      await handle(travelEndData);

      expect(notifier.shown, isEmpty);
    });

    test('shows when only another category is off', () async {
      disable('u-1', NotificationCategory.questEnd);

      await handle(travelEndData);

      expect(notifier.shown, hasLength(1));
    });

    test('ignores the toggles of another user', () async {
      for (final category in NotificationCategory.values) {
        disable('u-2', category);
      }

      await handle(travelEndData);

      expect(notifier.shown, hasLength(1));
    });

    test('drops an unknown type without throwing', () async {
      await handle({...travelEndData, 'type': 'combatResult'});

      expect(notifier.shown, isEmpty);
    });

    test('drops a message without a title', () async {
      await handle({...travelEndData}..remove('title'));

      expect(notifier.shown, isEmpty);
    });

    test('drops an unparseable sentAt', () async {
      await handle({...travelEndData, 'sentAt': 'yesterday'});

      expect(notifier.shown, isEmpty);
    });

    test('drops the message when preferences cannot be read', () async {
      preferences.readFailure = StateError('storage down');

      await handle(travelEndData);

      expect(notifier.shown, isEmpty);
    });

    test('drops the message when the active user cannot be read', () async {
      activeUser.readFailure = StateError('storage down');

      await handle(travelEndData);

      expect(notifier.shown, isEmpty);
    });

    test('reuses the notification id for the same event', () async {
      await handle(travelEndData);
      await handle(travelEndData);

      expect(notifier.shown, hasLength(2));
      expect(
        notifier.shown.first.notificationId,
        notifier.shown.last.notificationId,
      );
    });
  });

  group('acceptPushEvent', () {
    Future<PushEvent?> accept(Map<String, Object?> data, {String? userId}) =>
        acceptPushEvent(data, userId: userId, preferences: preferences);

    test('returns the event when its toggle is on', () async {
      expect(
        await accept(travelEndData, userId: 'u-1'),
        PushEvent.tryParse(travelEndData),
      );
    });

    test('returns null when its toggle is off', () async {
      disable('u-1', NotificationCategory.travelEnd);

      expect(await accept(travelEndData, userId: 'u-1'), isNull);
    });

    test('drops an ambush defeat when its toggle is off (D-10)', () async {
      disable('u-1', NotificationCategory.ambushDefeat);

      expect(await accept(ambushDefeatData, userId: 'u-1'), isNull);
    });

    test('the ambush toggle off keeps the other categories (D-10)', () async {
      disable('u-1', NotificationCategory.ambushDefeat);

      expect(
        await accept(travelEndData, userId: 'u-1'),
        PushEvent.tryParse(travelEndData),
      );
    });

    test('returns null without a user', () async {
      expect(await accept(travelEndData), isNull);
    });

    test('returns null for a malformed message', () async {
      expect(
        await accept({...travelEndData, 'type': 'combatResult'}, userId: 'u-1'),
        isNull,
      );
    });
  });
}
