import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/newsCubit/library_news_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fakes/in_memory_library_bookmarks_store.dart';
import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const String _characterId = 'c-1';

final Lore andogan = Lore.fromJson(
  loreJson(id: 'lore-andogan', name: 'Andogan'),
);
final Lore bosa = Lore.fromJson(loreJson(id: 'lore-bosa', name: 'Bosa'));
final Lore goblin = Lore.fromJson(
  loreJson(id: 'lore-goblin', type: 'enemy', name: 'Goblin'),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late InMemoryLibraryBookmarksStore bookmarks;
  late LibraryNewsCubit cubit;

  void answerWith(List<Lore> lore) =>
      when(() => graphQl.getAllLores()).thenAnswer((_) async => lore);

  void seedSeen(LibraryBook book, Set<String> ids) =>
      bookmarks.seen[InMemoryLibraryBookmarksStore.keyOf(_characterId, book)] =
          ids;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    bookmarks = InMemoryLibraryBookmarksStore();
    cubit = LibraryNewsCubit(
      graphQl,
      bookmarks: bookmarks,
      characterId: _characterId,
    );
  });

  tearDown(() => cubit.close());

  test('starts with no book holding news', () {
    expect(cubit.state, isEmpty);
  });

  test('a book holds news when one of its lore was never seen', () async {
    answerWith([andogan, bosa, goblin]);
    seedSeen(LibraryBook.places, {'lore-andogan'});
    seedSeen(LibraryBook.bestiary, {'lore-goblin'});

    await cubit.syncUnlockedLore(['lore-andogan', 'lore-bosa', 'lore-goblin']);

    expect(cubit.state, {LibraryBook.places});
  });

  test('a book never opened holds news as soon as it has a lore', () async {
    answerWith([goblin]);

    await cubit.syncUnlockedLore(['lore-goblin']);

    expect(cubit.state, {LibraryBook.bestiary});
  });

  test('reads the lore again only when the unlocked set changes', () async {
    answerWith([andogan]);

    await cubit.syncUnlockedLore(['lore-andogan']);
    await cubit.syncUnlockedLore(['lore-andogan']);
    verify(() => graphQl.getAllLores()).called(1);

    answerWith([andogan, bosa]);
    await cubit.syncUnlockedLore(['lore-andogan', 'lore-bosa']);
    verify(() => graphQl.getAllLores()).called(1);
  });

  test('recount drops a book once its lore have been seen', () async {
    answerWith([andogan]);
    await cubit.syncUnlockedLore(['lore-andogan']);
    expect(cubit.state, {LibraryBook.places});

    seedSeen(LibraryBook.places, {'lore-andogan'});
    await cubit.recount();

    expect(cubit.state, isEmpty);
    verify(() => graphQl.getAllLores()).called(1);
  });

  test('a failed read of the lore stays silent and is retried', () async {
    when(() => graphQl.getAllLores()).thenThrow(Exception('offline'));
    await cubit.syncUnlockedLore(['lore-andogan']);
    expect(cubit.state, isEmpty);

    answerWith([andogan]);
    await cubit.syncUnlockedLore(['lore-andogan']);
    expect(cubit.state, {LibraryBook.places});
  });

  test('an unreadable bookmark marks nothing', () async {
    answerWith([andogan]);
    bookmarks.readFailure = Exception('storage');

    await cubit.syncUnlockedLore(['lore-andogan']);

    expect(cubit.state, isEmpty);
  });
}
