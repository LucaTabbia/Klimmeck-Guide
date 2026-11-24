import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/storage/legal_consent_store.dart';

import '../../helpers/fakes/fake_shared_preferences_async.dart';

void main() {
  const key = SharedPreferencesLegalConsentStore.key;
  late FakeSharedPreferencesAsync backing;
  late SharedPreferencesLegalConsentStore store;

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    store = SharedPreferencesLegalConsentStore(preferences: () => backing);
  });

  test('remembers the accepted version under its key (D-10)', () async {
    await store.remember('2026-11-24');

    expect(key, 'klimmeck.legal.acceptedVersion');
    expect(backing.values[key], '2026-11-24');
    expect(await store.readAcceptedVersion(), '2026-11-24');
  });

  test('reads null when nothing was accepted', () async {
    expect(await store.readAcceptedVersion(), isNull);
  });

  test('forget removes the accepted version (D-10)', () async {
    await store.remember('2026-11-24');

    await store.forget();

    expect(await store.readAcceptedVersion(), isNull);
  });

  test('a second remember replaces the first (D-12)', () async {
    await store.remember('2026-11-24');

    await store.remember('2027-01-01');

    expect(await store.readAcceptedVersion(), '2027-01-01');
  });
}
