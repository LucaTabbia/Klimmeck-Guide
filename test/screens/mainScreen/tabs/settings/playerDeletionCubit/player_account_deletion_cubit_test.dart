import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

const _deleting = PlayerAccountDeletionState(isDeleting: true);
const _deleted = PlayerAccountDeletionState(hasDeleted: true);

void main() {
  late MockPlayerAccountDeletionRepository repository;

  setUp(() {
    repository = MockPlayerAccountDeletionRepository();
  });

  PlayerAccountDeletionCubit build() => PlayerAccountDeletionCubit(repository);

  test('starts idle without outcome', () {
    expect(build().state, const PlayerAccountDeletionState());
  });

  group('deletePlayer', () {
    blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
      'a deletion shows the spinner then the success (D-15)',
      build: build,
      setUp: () => when(
        () => repository.deletePlayerAccount(any()),
      ).thenAnswer((_) async {}),
      act: (cubit) => cubit.deletePlayer('rossa_k'),
      expect: () => [_deleting, _deleted],
      verify: (_) {
        verify(() => repository.deletePlayerAccount('rossa_k')).called(1);
      },
    );

    blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
      'a refusal reads its failure and allows a new try',
      build: build,
      act: (cubit) async {
        when(() => repository.deletePlayerAccount(any())).thenThrow(
          const PlayerAccountDeletionException(
            PlayerAccountDeletionFailure.accountNotFound,
          ),
        );
        await cubit.deletePlayer('rossa_k');
        when(
          () => repository.deletePlayerAccount(any()),
        ).thenAnswer((_) async {});
        await cubit.deletePlayer('rossa_kk');
      },
      expect: () => [
        _deleting,
        const PlayerAccountDeletionState(
          failure: PlayerAccountDeletionFailure.accountNotFound,
        ),
        _deleting,
        _deleted,
      ],
    );

    blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
      'an unexpected error ends as unknown',
      build: build,
      setUp: () => when(
        () => repository.deletePlayerAccount(any()),
      ).thenThrow(StateError('x')),
      act: (cubit) => cubit.deletePlayer('rossa_k'),
      expect: () => [
        _deleting,
        const PlayerAccountDeletionState(
          failure: PlayerAccountDeletionFailure.unknown,
        ),
      ],
    );

    blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
      'a second tap while deleting is ignored',
      build: build,
      act: (cubit) async {
        final completer = Completer<void>();
        when(
          () => repository.deletePlayerAccount(any()),
        ).thenAnswer((_) => completer.future);
        final first = cubit.deletePlayer('rossa_k');
        await cubit.deletePlayer('rossa_k');
        completer.complete();
        await first;
      },
      expect: () => [_deleting, _deleted],
      verify: (_) {
        verify(() => repository.deletePlayerAccount(any())).called(1);
      },
    );

    test('nothing happens after close', () async {
      final cubit = build();
      await cubit.close();

      await cubit.deletePlayer('rossa_k');

      verifyNever(() => repository.deletePlayerAccount(any()));
    });
  });

  blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
    'reset clears the last outcome',
    build: build,
    seed: () => const PlayerAccountDeletionState(
      failure: PlayerAccountDeletionFailure.twitchUnavailable,
    ),
    act: (cubit) => cubit.reset(),
    expect: () => [const PlayerAccountDeletionState()],
  );

  blocTest<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
    'a reset while deleting keeps the deletion in flight: no second deletion '
    'can start (WR-03)',
    build: build,
    act: (cubit) async {
      final completer = Completer<void>();
      when(
        () => repository.deletePlayerAccount(any()),
      ).thenAnswer((_) => completer.future);
      final first = cubit.deletePlayer('rossa_k');
      cubit.reset();
      final second = cubit.deletePlayer('altro_nome');
      completer.complete();
      await Future.wait([first, second]);
    },
    expect: () => [_deleting, _deleted],
    verify: (_) {
      verify(() => repository.deletePlayerAccount('rossa_k')).called(1);
      verifyNever(() => repository.deletePlayerAccount('altro_nome'));
    },
  );
}
