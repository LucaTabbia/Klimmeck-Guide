import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

const _deleting = AccountDeletionState(isDeleting: true);

void main() {
  late MockAccountDeletionRepository repository;

  setUp(() {
    repository = MockAccountDeletionRepository();
  });

  AccountDeletionCubit build() => AccountDeletionCubit(repository);

  test('starts idle without failure', () {
    expect(build().state, const AccountDeletionState());
  });

  group('deleteAccount', () {
    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'a deletion shows the spinner and keeps it after success (D-06)',
      build: build,
      setUp: () =>
          when(() => repository.deleteOwnAccount()).thenAnswer((_) async {}),
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [_deleting],
      verify: (_) {
        verify(() => repository.deleteOwnAccount()).called(1);
      },
    );

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'a refused deletion reads its failure (D-06)',
      build: build,
      setUp: () => when(() => repository.deleteOwnAccount()).thenThrow(
        const AccountDeletionException(
          AccountDeletionFailure.innkeeperProtected,
        ),
      ),
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        _deleting,
        const AccountDeletionState(
          failure: AccountDeletionFailure.innkeeperProtected,
        ),
      ],
    );

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'an unexpected error ends as unknown (no endless spinner)',
      build: build,
      setUp: () =>
          when(() => repository.deleteOwnAccount()).thenThrow(StateError('x')),
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        _deleting,
        const AccountDeletionState(failure: AccountDeletionFailure.unknown),
      ],
    );

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'a second tap while deleting is ignored',
      build: build,
      act: (cubit) async {
        final completer = Completer<void>();
        when(
          () => repository.deleteOwnAccount(),
        ).thenAnswer((_) => completer.future);
        final first = cubit.deleteAccount();
        await cubit.deleteAccount();
        completer.complete();
        await first;
      },
      expect: () => [_deleting],
      verify: (_) {
        verify(() => repository.deleteOwnAccount()).called(1);
      },
    );

    test('nothing happens after close', () async {
      final cubit = build();
      await cubit.close();

      await cubit.deleteAccount();

      verifyNever(() => repository.deleteOwnAccount());
    });

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'a failure arriving after close is harmless',
      build: build,
      act: (cubit) async {
        final completer = Completer<void>();
        when(
          () => repository.deleteOwnAccount(),
        ).thenAnswer((_) => completer.future);
        final future = cubit.deleteAccount();
        await cubit.close();
        completer.completeError(
          const AccountDeletionException(AccountDeletionFailure.connection),
        );
        await future;
      },
      expect: () => [_deleting],
      errors: () => isEmpty,
    );
  });
}
