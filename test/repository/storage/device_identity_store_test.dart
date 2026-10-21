import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/storage/device_identity_store.dart';

import '../../helpers/fakes/fake_shared_preferences_async.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final _backendDeviceId = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

void main() {
  const key = SharedPreferencesDeviceIdentityStore.key;
  late FakeSharedPreferencesAsync backing;
  late int generated;

  SharedPreferencesDeviceIdentityStore buildStore() =>
      SharedPreferencesDeviceIdentityStore(
        preferences: () => backing,
        generateId: () => 'generated-${++generated}',
      );

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    generated = 0;
  });

  test('uses the device-wide key', () {
    expect(key, 'klimmeck.push.deviceId');
  });

  test('creates and stores an id on first read', () async {
    final id = await buildStore().readOrCreate();

    expect(id, 'generated-1');
    expect(backing.values[key], 'generated-1');
  });

  test('a new store instance reuses the stored id', () async {
    final first = await buildStore().readOrCreate();
    final second = await buildStore().readOrCreate();

    expect(second, first);
    expect(generated, 1);
  });

  test('concurrent reads on a fresh store generate once', () async {
    final store = buildStore();

    final ids = await Future.wait([store.readOrCreate(), store.readOrCreate()]);

    expect(ids, ['generated-1', 'generated-1']);
    expect(generated, 1);
  });

  test('replaces a stored id the backend would reject', () async {
    backing.values[key] = 'bad id!';

    final id = await buildStore().readOrCreate();

    expect(id, 'generated-1');
    expect(backing.values[key], 'generated-1');
  });

  test('the default generator yields a UUID v4 the backend accepts', () async {
    final id = await SharedPreferencesDeviceIdentityStore(
      preferences: () => backing,
    ).readOrCreate();

    expect(id, matches(_uuidV4));
    expect(id, matches(_backendDeviceId));
  });

  test('a read failure propagates and the next call retries', () async {
    final store = buildStore();
    backing.readFailures.add(StateError('storage down'));

    await expectLater(store.readOrCreate(), throwsStateError);

    expect(await store.readOrCreate(), 'generated-1');
  });
}
