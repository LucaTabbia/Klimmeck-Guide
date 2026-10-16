import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/fake_shared_preferences_async.dart';

void main() {
  late FakeSharedPreferencesAsync backing;
  late SharedPreferencesNotificationPreferencesStore store;

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    store = SharedPreferencesNotificationPreferencesStore(
      preferences: () => backing,
    );
  });

  test('builds the per-user per-category key', () {
    expect(
      SharedPreferencesNotificationPreferencesStore.keyFor(
        testUserId,
        NotificationCategory.streamerLive,
      ),
      'klimmeck.notifications.user-test-id.streamer_live',
    );
  });

  test('keeps the preferences outside the session namespace', () {
    expect(
      SharedPreferencesNotificationPreferencesStore.keyPrefix,
      isNot(startsWith('klimmeck.session')),
    );
  });

  test('every category is enabled by default', () async {
    for (final category in NotificationCategory.values) {
      expect(await store.isEnabled(testUserId, category), isTrue);
    }
    expect(await store.readAll(testUserId), {
      NotificationCategory.travelEnd: true,
      NotificationCategory.streamerLive: true,
      NotificationCategory.questEnd: true,
    });
  });

  test('reading never writes defaults', () async {
    await store.readAll(testUserId);

    expect(backing.values, isEmpty);
  });

  test('setEnabled stores a boolean under the pinned key', () async {
    await store.setEnabled(
      testUserId,
      NotificationCategory.questEnd,
      enabled: false,
    );

    expect(backing.values, {
      'klimmeck.notifications.user-test-id.quest_end': false,
    });
  });

  test('a new store over the same backing reads the saved value', () async {
    await store.setEnabled(
      testUserId,
      NotificationCategory.questEnd,
      enabled: false,
    );

    final restarted = SharedPreferencesNotificationPreferencesStore(
      preferences: () => backing,
    );

    expect(await restarted.readAll(testUserId), {
      NotificationCategory.travelEnd: true,
      NotificationCategory.streamerLive: true,
      NotificationCategory.questEnd: false,
    });
  });

  test('users on the same device do not share toggles', () async {
    await store.setEnabled('a', NotificationCategory.travelEnd, enabled: false);

    expect(await store.isEnabled('a', NotificationCategory.travelEnd), isFalse);
    expect(await store.isEnabled('b', NotificationCategory.travelEnd), isTrue);
  });

  test('a write failure propagates to the caller', () async {
    backing.writeFailures.add(StateError('write failed'));

    expect(
      store.setEnabled(
        testUserId,
        NotificationCategory.travelEnd,
        enabled: false,
      ),
      throwsStateError,
    );
  });

  test('a value of the wrong type makes reads throw', () async {
    backing.values['klimmeck.notifications.user-test-id.travel_end'] = 'yes';

    await expectLater(
      store.isEnabled(testUserId, NotificationCategory.travelEnd),
      throwsA(isA<TypeError>()),
    );
    await expectLater(store.readAll(testUserId), throwsA(isA<TypeError>()));
  });

  test('builds without a registered platform plugin', () {
    expect(SharedPreferencesNotificationPreferencesStore.new, returnsNormally);
  });
}
