import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/repository/storage/new_entries_store.dart';

import '../../helpers/fakes/fake_shared_preferences_async.dart';

void main() {
  late FakeSharedPreferencesAsync backing;
  late SharedPreferencesNewEntriesStore store;

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    store = SharedPreferencesNewEntriesStore(preferences: () => backing);
  });

  test('builds the per-character per-category key', () {
    expect(
      SharedPreferencesNewEntriesStore.keyFor('c-1', NewEntryCategory.spells),
      'klimmeck.newEntries.c-1.spells',
    );
  });

  test('keeps the seen entries outside the session namespace', () {
    expect(
      SharedPreferencesNewEntriesStore.keyPrefix,
      isNot(startsWith('klimmeck.session')),
    );
  });

  test('a category never recorded has no seen entries', () async {
    expect(await store.readSeen('c-1', NewEntryCategory.items), isNull);
  });

  test('stores the seen ids sorted and reads them back as a set', () async {
    await store.writeSeen('c-1', NewEntryCategory.items, {'b', 'a'});

    expect(backing.values['klimmeck.newEntries.c-1.items'], ['a', 'b']);
    expect(await store.readSeen('c-1', NewEntryCategory.items), {'a', 'b'});
  });

  test('every category has its own storage key', () {
    expect(
      NewEntryCategory.values.map((category) => category.storageKey).toSet(),
      hasLength(NewEntryCategory.values.length),
    );
  });
}
