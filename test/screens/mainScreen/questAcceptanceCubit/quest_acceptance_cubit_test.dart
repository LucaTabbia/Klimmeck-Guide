import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockQuestAcceptanceRepository repository;

  setUp(() {
    repository = MockQuestAcceptanceRepository();
  });

  QuestAcceptanceCubit build() => QuestAcceptanceCubit(repository);

  When<Future<void>> stubAccept() => when(
    () => repository.accept(
      characterId: any(named: 'characterId'),
      questId: any(named: 'questId'),
    ),
  );

  test('starts idle', () {
    expect(build().state, const QuestAcceptanceIdle());
  });

  blocTest<QuestAcceptanceCubit, QuestAcceptanceState>(
    'emits accepting then accepted when the repository succeeds',
    setUp: () => stubAccept().thenAnswer((_) async {}),
    build: build,
    act: (cubit) => cubit.accept(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [QuestAccepting('q-1'), QuestAccepted('q-1')],
    verify: (_) => verify(
      () => repository.accept(characterId: 'c-1', questId: 'q-1'),
    ).called(1),
  );

  blocTest<QuestAcceptanceCubit, QuestAcceptanceState>(
    'emits the failure carried by the exception',
    setUp: () => stubAccept().thenThrow(
      const QuestAcceptanceException(QuestAcceptanceFailure.full),
    ),
    build: build,
    act: (cubit) => cubit.accept(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [
      QuestAccepting('q-1'),
      QuestAcceptanceFailed('q-1', QuestAcceptanceFailure.full),
    ],
  );

  blocTest<QuestAcceptanceCubit, QuestAcceptanceState>(
    'maps an unexpected error to unknown',
    setUp: () => stubAccept().thenThrow(StateError('boom')),
    build: build,
    act: (cubit) => cubit.accept(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [
      QuestAccepting('q-1'),
      QuestAcceptanceFailed('q-1', QuestAcceptanceFailure.unknown),
    ],
  );

  test('ignores a second accept while one is in flight', () async {
    final completer = Completer<void>();
    stubAccept().thenAnswer((_) => completer.future);
    final cubit = build();

    final first = cubit.accept(characterId: 'c-1', questId: 'q-1');
    await cubit.accept(characterId: 'c-1', questId: 'q-2');
    completer.complete();
    await first;

    verify(
      () => repository.accept(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).called(1);
    expect(cubit.state, const QuestAccepted('q-1'));
  });

  test('drops a late response after close', () async {
    final completer = Completer<void>();
    stubAccept().thenAnswer((_) => completer.future);
    final cubit = build();

    final pending = cubit.accept(characterId: 'c-1', questId: 'q-1');
    await cubit.close();
    completer.complete();
    await pending;

    expect(cubit.state, const QuestAccepting('q-1'));
  });

  blocTest<QuestAcceptanceCubit, QuestAcceptanceState>(
    'reset returns to idle after an outcome',
    setUp: () => stubAccept().thenAnswer((_) async {}),
    build: build,
    act: (cubit) async {
      await cubit.accept(characterId: 'c-1', questId: 'q-1');
      cubit.reset();
    },
    expect: () => const [
      QuestAccepting('q-1'),
      QuestAccepted('q-1'),
      QuestAcceptanceIdle(),
    ],
  );

  test('reset is ignored while accepting', () async {
    final completer = Completer<void>();
    stubAccept().thenAnswer((_) => completer.future);
    final cubit = build();

    final pending = cubit.accept(characterId: 'c-1', questId: 'q-1');
    cubit.reset();

    expect(cubit.state, const QuestAccepting('q-1'));
    completer.complete();
    await pending;
  });

  blocTest<QuestAcceptanceCubit, QuestAcceptanceState>(
    'two identical consecutive failures are both observable',
    setUp: () => stubAccept().thenThrow(
      const QuestAcceptanceException(QuestAcceptanceFailure.full),
    ),
    build: build,
    act: (cubit) async {
      await cubit.accept(characterId: 'c-1', questId: 'q-1');
      cubit.reset();
      await cubit.accept(characterId: 'c-1', questId: 'q-1');
    },
    expect: () => const [
      QuestAccepting('q-1'),
      QuestAcceptanceFailed('q-1', QuestAcceptanceFailure.full),
      QuestAcceptanceIdle(),
      QuestAccepting('q-1'),
      QuestAcceptanceFailed('q-1', QuestAcceptanceFailure.full),
    ],
  );
}
