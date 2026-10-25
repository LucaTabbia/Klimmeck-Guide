import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockQuestAbandonRepository repository;

  setUp(() {
    repository = MockQuestAbandonRepository();
  });

  QuestAbandonCubit build() => QuestAbandonCubit(repository);

  When<Future<void>> stubAbandon() => when(
    () => repository.abandon(
      characterId: any(named: 'characterId'),
      questId: any(named: 'questId'),
    ),
  );

  test('starts idle', () {
    expect(build().state, const QuestAbandonIdle());
  });

  blocTest<QuestAbandonCubit, QuestAbandonState>(
    'emits abandoning then abandoned when the repository succeeds',
    setUp: () => stubAbandon().thenAnswer((_) async {}),
    build: build,
    act: (cubit) => cubit.abandon(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [QuestAbandoning('q-1'), QuestAbandoned('q-1')],
    verify: (_) => verify(
      () => repository.abandon(characterId: 'c-1', questId: 'q-1'),
    ).called(1),
  );

  blocTest<QuestAbandonCubit, QuestAbandonState>(
    'emits the failure carried by the exception',
    setUp: () => stubAbandon().thenThrow(
      const QuestAbandonException(QuestAbandonFailure.notWaiting),
    ),
    build: build,
    act: (cubit) => cubit.abandon(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [
      QuestAbandoning('q-1'),
      QuestAbandonFailed('q-1', QuestAbandonFailure.notWaiting),
    ],
  );

  blocTest<QuestAbandonCubit, QuestAbandonState>(
    'maps an unexpected error to unknown',
    setUp: () => stubAbandon().thenThrow(StateError('boom')),
    build: build,
    act: (cubit) => cubit.abandon(characterId: 'c-1', questId: 'q-1'),
    expect: () => const [
      QuestAbandoning('q-1'),
      QuestAbandonFailed('q-1', QuestAbandonFailure.unknown),
    ],
  );

  test('ignores a second abandon while one is in flight', () async {
    final completer = Completer<void>();
    stubAbandon().thenAnswer((_) => completer.future);
    final cubit = build();

    final first = cubit.abandon(characterId: 'c-1', questId: 'q-1');
    await cubit.abandon(characterId: 'c-1', questId: 'q-2');
    completer.complete();
    await first;

    verify(
      () => repository.abandon(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).called(1);
    expect(cubit.state, const QuestAbandoned('q-1'));
  });

  test('drops a late response after close', () async {
    final completer = Completer<void>();
    stubAbandon().thenAnswer((_) => completer.future);
    final cubit = build();

    final pending = cubit.abandon(characterId: 'c-1', questId: 'q-1');
    await cubit.close();
    completer.complete();
    await pending;

    expect(cubit.state, const QuestAbandoning('q-1'));
  });

  blocTest<QuestAbandonCubit, QuestAbandonState>(
    'reset returns to idle after an outcome',
    setUp: () => stubAbandon().thenAnswer((_) async {}),
    build: build,
    act: (cubit) async {
      await cubit.abandon(characterId: 'c-1', questId: 'q-1');
      cubit.reset();
    },
    expect: () => const [
      QuestAbandoning('q-1'),
      QuestAbandoned('q-1'),
      QuestAbandonIdle(),
    ],
  );

  test('reset is ignored while abandoning', () async {
    final completer = Completer<void>();
    stubAbandon().thenAnswer((_) => completer.future);
    final cubit = build();

    final pending = cubit.abandon(characterId: 'c-1', questId: 'q-1');
    cubit.reset();

    expect(cubit.state, const QuestAbandoning('q-1'));
    completer.complete();
    await pending;
  });
}
