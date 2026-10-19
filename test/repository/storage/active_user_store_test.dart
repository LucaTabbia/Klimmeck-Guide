import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/storage/active_user_store.dart';

import '../../helpers/fakes/fake_shared_preferences_async.dart';

void main() {
  const key = SharedPreferencesActiveUserStore.key;
  late FakeSharedPreferencesAsync backing;
  late SharedPreferencesActiveUserStore store;

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    store = SharedPreferencesActiveUserStore(preferences: () => backing);
  });

  test('uses the device-wide key', () {
    expect(key, 'klimmeck.push.activeUserId');
  });

  test('reads null when no user is active', () async {
    expect(await store.read(), isNull);
  });

  test('reads back the written user under the key', () async {
    await store.write('u-1');

    expect(await store.read(), 'u-1');
    expect(backing.values[key], 'u-1');
  });

  test('clear removes the active user', () async {
    await store.write('u-1');

    await store.clear();

    expect(await store.read(), isNull);
  });

  test('clear on empty storage does not throw', () async {
    await expectLater(store.clear(), completes);
  });

  test('a new store instance reads the written user', () async {
    await store.write('u-1');

    final other = SharedPreferencesActiveUserStore(preferences: () => backing);

    expect(await other.read(), 'u-1');
  });
}
