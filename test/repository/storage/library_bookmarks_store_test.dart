import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/repository/storage/library_bookmarks_store.dart';

import '../../helpers/fakes/fake_shared_preferences_async.dart';

void main() {
  late FakeSharedPreferencesAsync backing;
  late SharedPreferencesLibraryBookmarksStore store;

  setUp(() {
    backing = FakeSharedPreferencesAsync();
    store = SharedPreferencesLibraryBookmarksStore(preferences: () => backing);
  });

  test('builds the per-character per-book key (D-07)', () {
    expect(
      SharedPreferencesLibraryBookmarksStore.keyFor('c-1', LibraryBook.places),
      'klimmeck.library.c-1.places',
    );
  });

  test('keeps the bookmarks outside the session namespace (D-07)', () {
    expect(
      SharedPreferencesLibraryBookmarksStore.keyPrefix,
      isNot(startsWith('klimmeck.session')),
    );
  });

  test('a book never opened has no baseline (D-07)', () async {
    expect(await store.readSeen('c-1', LibraryBook.places), isNull);
  });

  test(
    'stores the seen ids sorted and reads them back as a set (D-07)',
    () async {
      await store.writeSeen('c-1', LibraryBook.places, {'b', 'a'});

      expect(backing.values['klimmeck.library.c-1.places'], ['a', 'b']);
      expect(await store.readSeen('c-1', LibraryBook.places), {'a', 'b'});
    },
  );

  test('a book opened empty has an empty baseline, not none (D-07)', () async {
    await store.writeSeen('c-1', LibraryBook.places, {});

    final seen = await store.readSeen('c-1', LibraryBook.places);

    expect(seen, isNotNull);
    expect(seen, <String>{});
  });

  test('two characters never share a baseline (D-07)', () async {
    await store.writeSeen('c-1', LibraryBook.places, {'a'});

    expect(await store.readSeen('c-2', LibraryBook.places), isNull);
  });

  test('two books never share a baseline (D-07)', () async {
    await store.writeSeen('c-1', LibraryBook.places, {'a'});

    expect(await store.readSeen('c-1', LibraryBook.bestiary), isNull);
  });

  test('a new write replaces the previous baseline (D-07)', () async {
    await store.writeSeen('c-1', LibraryBook.places, {'a', 'b'});
    await store.writeSeen('c-1', LibraryBook.places, {'c'});

    expect(await store.readSeen('c-1', LibraryBook.places), {'c'});
  });

  test('storage failures reach the caller (D-07)', () async {
    backing.readFailures.add(StateError('read'));
    backing.writeFailures.add(StateError('write'));

    await expectLater(
      store.readSeen('c-1', LibraryBook.places),
      throwsStateError,
    );
    await expectLater(
      store.writeSeen('c-1', LibraryBook.places, {'a'}),
      throwsStateError,
    );
  });

  test('builds without a registered platform plugin', () {
    expect(SharedPreferencesLibraryBookmarksStore.new, returnsNormally);
  });
}
