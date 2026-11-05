import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockInnkeeperRepository repository;

  setUp(() => repository = MockInnkeeperRepository());

  QuestGenerationCubit build() => QuestGenerationCubit(repository: repository);

  test('starts idle (D-10)', () async {
    final cubit = build();

    expect(cubit.state, const QuestGenerationIdle());
    await cubit.close();
  });

  blocTest<QuestGenerationCubit, QuestGenerationState>(
    'emits submitting then succeeded with created (D-10)',
    setUp: () =>
        when(() => repository.generateQuests()).thenAnswer((_) async => 3),
    build: build,
    act: (cubit) => cubit.generate(),
    expect: () => const [
      QuestGenerationSubmitting(),
      QuestGenerationSucceeded(created: 3),
    ],
  );

  blocTest<QuestGenerationCubit, QuestGenerationState>(
    'zero created is a success, not a failure (D-09)',
    setUp: () =>
        when(() => repository.generateQuests()).thenAnswer((_) async => 0),
    build: build,
    act: (cubit) => cubit.generate(),
    expect: () => const [
      QuestGenerationSubmitting(),
      QuestGenerationSucceeded(created: 0),
    ],
  );

  blocTest<QuestGenerationCubit, QuestGenerationState>(
    'emits submitting then failed with the failure and serial 1 (D-09)',
    setUp: () => when(
      () => repository.generateQuests(),
    ).thenThrow(const InnkeeperException(InnkeeperFailure.forbidden)),
    build: build,
    act: (cubit) => cubit.generate(),
    expect: () => const [
      QuestGenerationSubmitting(),
      QuestGenerationFailed(failure: InnkeeperFailure.forbidden, serial: 1),
    ],
  );

  blocTest<QuestGenerationCubit, QuestGenerationState>(
    'two failures with the same code carry different serials (D-10)',
    setUp: () => when(
      () => repository.generateQuests(),
    ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
    build: build,
    act: (cubit) async {
      await cubit.generate();
      await cubit.generate();
    },
    expect: () => const [
      QuestGenerationSubmitting(),
      QuestGenerationFailed(failure: InnkeeperFailure.connection, serial: 1),
      QuestGenerationSubmitting(),
      QuestGenerationFailed(failure: InnkeeperFailure.connection, serial: 2),
    ],
  );

  test('ignores generate while submitting (D-09)', () async {
    final answer = Completer<int>();
    when(() => repository.generateQuests()).thenAnswer((_) => answer.future);
    final cubit = build();

    final first = cubit.generate();
    final second = cubit.generate();
    answer.complete(2);
    await Future.wait([first, second]);

    verify(() => repository.generateQuests()).called(1);
    expect(cubit.state, const QuestGenerationSucceeded(created: 2));
    await cubit.close();
  });

  test('a closed cubit emits nothing after the answer (D-10)', () async {
    final answer = Completer<int>();
    when(() => repository.generateQuests()).thenAnswer((_) => answer.future);
    final cubit = build();

    final pending = cubit.generate();
    await cubit.close();
    answer.complete(1);

    await expectLater(pending, completes);
    expect(cubit.state, const QuestGenerationSubmitting());
  });
}
