import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes/in_memory_session_store.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const refreshKey = SecureSessionStore.refreshTokenKey;
  const markerKey = SecureSessionStore.firstLaunchDoneKey;

  void givenPrefs(Map<String, Object> values) =>
      SharedPreferences.setMockInitialValues(values);

  group('SecureSessionStore', () {
    test(
      'first launch wipes the encrypted storage and sets the marker',
      () async {
        givenPrefs({});
        FlutterSecureStorage.setMockInitialValues({refreshKey: 'old'});
        final store = SecureSessionStore();

        expect(await store.readRefreshToken(), isNull);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(markerKey), isTrue);
      },
    );

    test('returns the stored token once the marker is present', () async {
      givenPrefs({markerKey: true});
      FlutterSecureStorage.setMockInitialValues({refreshKey: 'r1'});

      expect(await SecureSessionStore().readRefreshToken(), 'r1');
    });

    test('write then read round trips, clear removes it', () async {
      givenPrefs({markerKey: true});
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureSessionStore();

      await store.writeRefreshToken('r2');
      expect(await store.readRefreshToken(), 'r2');

      await store.clear();
      expect(await store.readRefreshToken(), isNull);
    });

    test('a throwing read means no session now and wipes nothing', () async {
      givenPrefs({markerKey: true});
      final storage = MockFlutterSecureStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenThrow(PlatformException(code: '-25308'));
      when(() => storage.deleteAll()).thenAnswer((_) async {});
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      expect(
        await SecureSessionStore(storage: storage).readRefreshToken(),
        isNull,
      );
      verifyNever(() => storage.deleteAll());
      verifyNever(() => storage.delete(key: any(named: 'key')));
    });

    test(
      'unreadable preferences are not a first launch: nothing is wiped',
      () async {
        final storage = MockFlutterSecureStorage();
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'r1');
        when(() => storage.deleteAll()).thenAnswer((_) async {});

        final store = SecureSessionStore(
          storage: storage,
          preferences: () async => throw PlatformException(code: 'io'),
        );

        expect(await store.readRefreshToken(), 'r1');
        verifyNever(() => storage.deleteAll());
      },
    );

    test('a marker that cannot be saved does not wipe the storage', () async {
      final storage = MockFlutterSecureStorage();
      final prefs = MockSharedPreferences();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'r1');
      when(() => storage.deleteAll()).thenAnswer((_) async {});
      when(() => prefs.getBool(markerKey)).thenReturn(null);
      when(
        () => prefs.setBool(markerKey, true),
      ).thenAnswer((_) async => throw PlatformException(code: 'io'));

      final store = SecureSessionStore(
        storage: storage,
        preferences: () async => prefs,
      );

      expect(await store.readRefreshToken(), 'r1');
      verifyNever(() => storage.deleteAll());
    });

    test('android plugin resets only unrecoverable storage', () {
      expect(
        SecureSessionStore.defaultStorage.aOptions.toMap()['resetOnError'],
        'true',
      );
    });

    test('never writes the refresh token to shared preferences', () async {
      givenPrefs({});
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureSessionStore();

      await store.readRefreshToken();
      await store.writeRefreshToken('secret-refresh');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((key) => key.contains('refresh')), isEmpty);
      expect(
        prefs
            .getKeys()
            .map(prefs.get)
            .whereType<String>()
            .where((value) => value.contains('secret-refresh')),
        isEmpty,
      );
    });
  });

  group('InMemorySessionStore', () {
    test('reads, writes, clears and counts writes', () async {
      final store = InMemorySessionStore();

      await store.writeRefreshToken('a');
      expect(await store.readRefreshToken(), 'a');
      expect(store.writes, 1);

      await store.clear();
      expect(await store.readRefreshToken(), isNull);
    });

    test('failNextWrite makes only the next write throw', () async {
      final store = InMemorySessionStore()..failNextWrite = true;

      await expectLater(store.writeRefreshToken('a'), throwsStateError);
      await store.writeRefreshToken('b');
      expect(store.refreshToken, 'b');
    });
  });
}
