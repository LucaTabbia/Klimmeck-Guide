import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fakes/in_memory_library_bookmarks_store.dart';
import '../../../../../helpers/fixtures/lore_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const String _characterId = 'c-1';

final Lore andogan = Lore.fromJson(
  loreJson(id: 'lore-andogan', name: 'Andogan'),
);
final Lore bosa = Lore.fromJson(loreJson(id: 'lore-bosa', name: 'Bosa'));
final Lore valtorre = Lore.fromJson(
  loreJson(id: 'lore-valtorre', type: 'region', name: 'Valtorre'),
);
final Lore drustea = Lore.fromJson(
  loreJson(id: 'lore-drustea', type: 'state', name: 'Drustea'),
);
final Lore goblin = Lore.fromJson(
  loreJson(id: 'lore-goblin', type: 'enemy', name: 'Goblin'),
);

Set<String> _ids(List<Lore> lore) => {for (final entry in lore) entry.id};

void main() {
  late MockKlimmeckGraphQl graphQl;
  late InMemoryLibraryBookmarksStore bookmarks;
  late List<Future<List<Lore>> Function()> answers;

  LibraryCubit buildCubit() =>
      LibraryCubit(graphQl, bookmarks: bookmarks, characterId: _characterId);

  void answerWith(List<Lore> lore) => answers.add(() async => lore);

  Completer<List<Lore>> holdNextAnswer() {
    final held = Completer<List<Lore>>();
    answers.add(() => held.future);
    return held;
  }

  void seedBaseline(LibraryBook book, Set<String> ids) =>
      bookmarks.seen[InMemoryLibraryBookmarksStore.keyOf(_characterId, book)] =
          ids;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    bookmarks = InMemoryLibraryBookmarksStore();
    answers = [];
    when(() => graphQl.getAllLores()).thenAnswer((_) => answers.removeAt(0)());
  });

  group('openBook', () {
    blocTest<LibraryCubit, LibraryState>(
      'opening a book for the first time marks nothing and records what it shows (D-07)',
      setUp: () => answerWith([andogan, bosa, valtorre, drustea, goblin]),
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.places),
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa, valtorre, drustea],
          newLoreIds: const {},
        ),
      ],
      verify: (_) => expect(
        bookmarks.seenOf(_characterId, LibraryBook.places),
        _ids([andogan, bosa, valtorre, drustea]),
      ),
    );

    blocTest<LibraryCubit, LibraryState>(
      'opening keeps only the lore of that book (D-06)',
      setUp: () => answerWith([andogan, bosa, valtorre, drustea, goblin]),
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.bestiary),
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.bestiary,
          lore: [goblin],
          newLoreIds: const {},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'opening marks the entries missing from the previous opening (D-07)',
      setUp: () {
        seedBaseline(LibraryBook.places, {andogan.id});
        answerWith([andogan, bosa, valtorre, drustea]);
      },
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.places),
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa, valtorre, drustea],
          newLoreIds: _ids([bosa, valtorre, drustea]),
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'a reopened book carries no mark of the previous session (D-07)',
      setUp: () {
        seedBaseline(LibraryBook.places, {andogan.id});
        answerWith([andogan, bosa]);
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.openBook(LibraryBook.places);
        cubit.goToInitial();
        await cubit.openBook(LibraryBook.places);
      },
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: {bosa.id},
        ),
        const LibraryInitial(),
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: const {},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'an unreadable baseline marks nothing and never fails the opening (D-07)',
      setUp: () {
        bookmarks.readFailure = StateError('read');
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.places),
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: const {},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'a failed baseline write still shows the book (D-07)',
      setUp: () {
        bookmarks.writeFailure = StateError('write');
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.places),
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: const {},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'a failed opening shows the error state, an explicit tap (D-05)',
      setUp: () => answers.add(() async => throw StateError('offline')),
      build: buildCubit,
      act: (cubit) => cubit.openBook(LibraryBook.places),
      expect: () => [const LibraryLoading(), isA<LibraryError>()],
    );
  });

  group('syncUnlockedLore', () {
    blocTest<LibraryCubit, LibraryState>(
      'the first set received only records it (D-05)',
      setUp: () => answerWith([andogan]),
      build: buildCubit,
      act: (cubit) async {
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['a']);
      },
      skip: 2,
      expect: () => <LibraryState>[],
      verify: (_) => verify(() => graphQl.getAllLores()).called(1),
    );

    blocTest<LibraryCubit, LibraryState>(
      'a change of the unlocked set refetches the open book silently (D-05, D-19)',
      setUp: () {
        answerWith([andogan]);
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['a', 'b']);
      },
      skip: 2,
      expect: () => [
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: {bosa.id},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'the same set in another order or with repeats refetches nothing (D-05)',
      setUp: () => answerWith([andogan]),
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a', 'b']);
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['b', 'a', 'a']);
      },
      skip: 2,
      expect: () => <LibraryState>[],
      verify: (_) => verify(() => graphQl.getAllLores()).called(1),
    );

    blocTest<LibraryCubit, LibraryState>(
      'a change with no open book only records it (D-05)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a']);
        await cubit.syncUnlockedLore(['a', 'b']);
      },
      expect: () => <LibraryState>[],
      verify: (_) => verifyNever(() => graphQl.getAllLores()),
    );

    blocTest<LibraryCubit, LibraryState>(
      'a live arrival is marked against the opening reference and recorded (D-07)',
      setUp: () {
        seedBaseline(LibraryBook.places, {andogan.id});
        answerWith([andogan, bosa]);
        answerWith([andogan, bosa, valtorre]);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['a', 'b']);
      },
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: {bosa.id},
        ),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa, valtorre],
          newLoreIds: {bosa.id, valtorre.id},
        ),
      ],
      verify: (_) => expect(
        bookmarks.seenOf(_characterId, LibraryBook.places),
        _ids([andogan, bosa, valtorre]),
      ),
    );

    blocTest<LibraryCubit, LibraryState>(
      'without a previous baseline a live arrival is marked against the first shown set (D-07)',
      setUp: () {
        answerWith([andogan]);
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['a', 'b']);
      },
      expect: () => [
        const LibraryLoading(),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan],
          newLoreIds: const {},
        ),
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: {bosa.id},
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'a failed refresh keeps the page and emits nothing (D-05)',
      setUp: () {
        answerWith([andogan]);
        answers.add(() async => throw StateError('offline'));
        answerWith([andogan, bosa]);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        await cubit.syncUnlockedLore(['a', 'b']);
        expect(
          cubit.state,
          LibraryLoadData(
            book: LibraryBook.places,
            lore: [andogan],
            newLoreIds: const {},
          ),
        );
        await cubit.syncUnlockedLore(['a', 'b', 'c']);
      },
      skip: 2,
      expect: () => [
        LibraryLoadData(
          book: LibraryBook.places,
          lore: [andogan, bosa],
          newLoreIds: {bosa.id},
        ),
      ],
      verify: (_) => verify(() => graphQl.getAllLores()).called(3),
    );

    test(
      'a refresh completing after goToInitial is dropped (D-05, D-19)',
      () async {
        answerWith([andogan]);
        final held = holdNextAnswer();
        final cubit = buildCubit();
        final states = <LibraryState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        final refresh = cubit.syncUnlockedLore(['a', 'b']);
        cubit.goToInitial();
        held.complete([andogan, bosa]);
        await refresh;
        await Future<void>.delayed(Duration.zero);

        expect(states.last, const LibraryInitial());
        expect(states.whereType<LibraryLoadData>(), hasLength(1));
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      'a refresh completing after another book opened is dropped (D-05, D-19)',
      () async {
        answerWith([andogan, goblin]);
        final held = holdNextAnswer();
        answerWith([andogan, goblin]);
        final cubit = buildCubit();
        final states = <LibraryState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        final refresh = cubit.syncUnlockedLore(['a', 'b']);
        await cubit.openBook(LibraryBook.bestiary);
        held.complete([andogan, bosa, goblin]);
        await refresh;
        await Future<void>.delayed(Duration.zero);

        expect(
          states.last,
          LibraryLoadData(
            book: LibraryBook.bestiary,
            lore: [goblin],
            newLoreIds: const {},
          ),
        );
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      'changes during a refresh in flight run one trailing refresh (D-05)',
      () async {
        answerWith([andogan]);
        final held = holdNextAnswer();
        answerWith([andogan, bosa, valtorre]);
        final cubit = buildCubit();

        await cubit.syncUnlockedLore(['a']);
        await cubit.openBook(LibraryBook.places);
        final refresh = cubit.syncUnlockedLore(['a', 'b']);
        await cubit.syncUnlockedLore(['a', 'b', 'c']);
        await cubit.syncUnlockedLore(['a', 'b', 'c', 'd']);
        held.complete([andogan, bosa]);
        await refresh;

        verify(() => graphQl.getAllLores()).called(3);
        expect(
          cubit.state,
          LibraryLoadData(
            book: LibraryBook.places,
            lore: [andogan, bosa, valtorre],
            newLoreIds: {bosa.id, valtorre.id},
          ),
        );
        await cubit.close();
      },
    );
  });
}
