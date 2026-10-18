import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/auth_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const _deleting = CharacterDeletionState(isDeleting: true);

CharacterDeletionException _exception(CharacterDeletionFailure failure) =>
    CharacterDeletionException(failure);

CharacterDeletionState _failed(CharacterDeletionFailure failure) =>
    CharacterDeletionState(failure: failure);

void main() {
  late MockCharacterDeletionRepository repository;

  setUp(() {
    repository = MockCharacterDeletionRepository();
  });

  CharacterDeletionCubit build() => CharacterDeletionCubit(repository);

  test('starts idle without failure or hand-over', () {
    const state = CharacterDeletionState();

    expect(build().state, state);
    expect(state.isDeleting, isFalse);
    expect(state.failure, isNull);
    expect(state.deletedUser, isNull);
  });

  group('deleteCharacter', () {
    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'hands the returned user over and stays deleting',
      build: build,
      setUp: () => when(
        () => repository.deleteCurrentCharacter(),
      ).thenAnswer((_) async => buildTestUser()),
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [
        _deleting,
        CharacterDeletionState(isDeleting: true, deletedUser: buildTestUser()),
      ],
      verify: (_) {
        verifyNever(() => repository.fetchCurrentUser());
      },
    );

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'notFound with a character-less user on refetch hands over normally',
      build: build,
      setUp: () {
        when(
          () => repository.deleteCurrentCharacter(),
        ).thenThrow(_exception(CharacterDeletionFailure.notFound));
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => buildTestUser());
      },
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [
        _deleting,
        CharacterDeletionState(isDeleting: true, deletedUser: buildTestUser()),
      ],
    );

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'notFound while the refetched user still has a character fails unknown',
      build: build,
      setUp: () {
        when(
          () => repository.deleteCurrentCharacter(),
        ).thenThrow(_exception(CharacterDeletionFailure.notFound));
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => buildTestUserWithCharacter());
      },
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [_deleting, _failed(CharacterDeletionFailure.unknown)],
    );

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'notFound with a failing refetch fails unknown',
      build: build,
      setUp: () {
        when(
          () => repository.deleteCurrentCharacter(),
        ).thenThrow(_exception(CharacterDeletionFailure.notFound));
        when(
          () => repository.fetchCurrentUser(),
        ).thenThrow(_exception(CharacterDeletionFailure.connection));
      },
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [_deleting, _failed(CharacterDeletionFailure.unknown)],
    );

    for (final failure in [
      CharacterDeletionFailure.connection,
      CharacterDeletionFailure.unauthenticated,
    ]) {
      blocTest<CharacterDeletionCubit, CharacterDeletionState>(
        '${failure.name} ends in a retryable failure state',
        build: build,
        setUp: () => when(
          () => repository.deleteCurrentCharacter(),
        ).thenThrow(_exception(failure)),
        act: (cubit) => cubit.deleteCharacter(),
        expect: () => [_deleting, _failed(failure)],
        verify: (_) {
          verifyNever(() => repository.fetchCurrentUser());
        },
      );
    }

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'an unexpected error ends in unknown, never stuck deleting',
      build: build,
      setUp: () => when(
        () => repository.deleteCurrentCharacter(),
      ).thenThrow(StateError('boom')),
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [_deleting, _failed(CharacterDeletionFailure.unknown)],
    );

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'a retry after a failure clears it and can succeed',
      build: build,
      seed: () => _failed(CharacterDeletionFailure.connection),
      setUp: () => when(
        () => repository.deleteCurrentCharacter(),
      ).thenAnswer((_) async => buildTestUser()),
      act: (cubit) => cubit.deleteCharacter(),
      expect: () => [
        _deleting,
        CharacterDeletionState(isDeleting: true, deletedUser: buildTestUser()),
      ],
    );

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'a second call while one is in flight is ignored',
      build: build,
      act: (cubit) async {
        final completer = Completer<User>();
        when(
          () => repository.deleteCurrentCharacter(),
        ).thenAnswer((_) => completer.future);
        final first = cubit.deleteCharacter();
        await cubit.deleteCharacter();
        completer.complete(buildTestUser());
        await first;
      },
      expect: () => [
        _deleting,
        CharacterDeletionState(isDeleting: true, deletedUser: buildTestUser()),
      ],
      verify: (_) {
        verify(() => repository.deleteCurrentCharacter()).called(1);
      },
    );

    test('a closed cubit does not call the repository', () async {
      final cubit = build();
      await cubit.close();

      await cubit.deleteCharacter();

      verifyNever(() => repository.deleteCurrentCharacter());
    });

    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'a response arriving after close is harmless',
      build: build,
      act: (cubit) async {
        final completer = Completer<User>();
        when(
          () => repository.deleteCurrentCharacter(),
        ).thenAnswer((_) => completer.future);
        final future = cubit.deleteCharacter();
        await cubit.close();
        completer.complete(buildTestUser());
        await future;
      },
      expect: () => [_deleting],
      errors: () => isEmpty,
    );
  });

  group('handoverRejected', () {
    blocTest<CharacterDeletionCubit, CharacterDeletionState>(
      'unblocks the screen and reports the rejected hand-over',
      build: build,
      seed: () => CharacterDeletionState(
        isDeleting: true,
        deletedUser: buildTestUser(),
      ),
      act: (cubit) => cubit.handoverRejected(),
      expect: () => [_failed(CharacterDeletionFailure.handoverRejected)],
    );
  });
}
