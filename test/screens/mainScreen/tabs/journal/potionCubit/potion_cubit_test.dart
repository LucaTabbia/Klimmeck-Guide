import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/potion_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const _herb = 'l-herb';
const _worg = 'pet-worg';
const _worgName = 'Fulmine';

void main() {
  late MockItemUseRepository repository;
  final result = UseItemResult.fromJson(useItemResultJson());
  final recoveryEnd = DateTime.utc(2026, 10, 27, 10, 30);

  setUp(() {
    repository = MockItemUseRepository();
  });

  PotionCubit build() => PotionCubit(repository);

  When<Future<UseItemResult>> stubUseItem() =>
      when(() => repository.useItem(any(), petId: any(named: 'petId')));

  test('starts idle', () {
    final cubit = build();

    expect(cubit.state, const PotionIdle());
    cubit.close();
  });

  blocTest<PotionCubit, PotionState>(
    'drinking emits PotionDrinking then PotionDrunk with the server result '
    '(D-11)',
    setUp: () => stubUseItem().thenAnswer((_) async => result),
    build: build,
    act: (cubit) => cubit.drink(_herb),
    expect: () => [const PotionDrinking(_herb), PotionDrunk(_herb, result)],
    verify: (_) => verify(() => repository.useItem(_herb)).called(1),
  );

  blocTest<PotionCubit, PotionState>(
    'a refusal emits PotionRefused with the failure (D-11)',
    setUp: () => stubUseItem().thenThrow(
      const ItemUseException(ItemUseFailure.noEffect),
    ),
    build: build,
    act: (cubit) => cubit.drink(_herb),
    expect: () => const [
      PotionDrinking(_herb),
      PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 1),
    ],
  );

  blocTest<PotionCubit, PotionState>(
    'a recovery refusal carries the server date (D-19)',
    setUp: () => stubUseItem().thenThrow(
      ItemUseException(
        ItemUseFailure.potionRecovering,
        recoveryUntil: recoveryEnd,
      ),
    ),
    build: build,
    act: (cubit) => cubit.drink(_herb),
    expect: () => [
      const PotionDrinking(_herb),
      isA<PotionRefused>()
          .having((s) => s.failure, 'failure', ItemUseFailure.potionRecovering)
          .having((s) => s.recoveryUntil, 'recoveryUntil', recoveryEnd),
    ],
  );

  blocTest<PotionCubit, PotionState>(
    'two identical refusals in a row are two different states (D-19)',
    setUp: () => stubUseItem().thenThrow(
      const ItemUseException(ItemUseFailure.noEffect),
    ),
    build: build,
    act: (cubit) async {
      await cubit.drink(_herb);
      await cubit.drink(_herb);
    },
    expect: () => const [
      PotionDrinking(_herb),
      PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 1),
      PotionDrinking(_herb),
      PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 2),
    ],
    verify: (_) {
      const first = PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 1);
      const second = PotionRefused(_herb, ItemUseFailure.noEffect, sequence: 2);
      expect(second, isNot(first));
    },
  );

  blocTest<PotionCubit, PotionState>(
    'an unexpected error is an unknown refusal (D-11)',
    setUp: () => stubUseItem().thenThrow(StateError('boom')),
    build: build,
    act: (cubit) => cubit.drink(_herb),
    expect: () => const [
      PotionDrinking(_herb),
      PotionRefused(_herb, ItemUseFailure.unknown, sequence: 1),
    ],
  );

  test('a second drink while drinking makes no call (D-11)', () async {
    final pending = Completer<UseItemResult>();
    stubUseItem().thenAnswer((_) => pending.future);
    final cubit = build();

    final first = cubit.drink(_herb);
    await cubit.drink(_herb);
    await cubit.drink('l-other');
    pending.complete(result);
    await first;

    verify(() => repository.useItem(_herb)).called(1);
    verifyNever(() => repository.useItem('l-other'));
    expect(cubit.state, PotionDrunk(_herb, result));
    await cubit.close();
  });

  blocTest<PotionCubit, PotionState>(
    'give sends the target and emits Drinking → Drunk with the target '
    '(D-07, D-23)',
    setUp: () => stubUseItem().thenAnswer((_) async => result),
    build: build,
    act: (cubit) => cubit.give(_herb, petId: _worg, targetName: _worgName),
    expect: () => [
      const PotionDrinking(_herb, targetPetId: _worg, targetName: _worgName),
      PotionDrunk(_herb, result, targetPetId: _worg, targetName: _worgName),
    ],
    verify: (_) =>
        verify(() => repository.useItem(_herb, petId: _worg)).called(1),
  );

  blocTest<PotionCubit, PotionState>(
    'a refused give carries the target name and the served wait (D-05, D-32)',
    setUp: () => stubUseItem().thenThrow(
      ItemUseException(
        ItemUseFailure.petPotionRecovering,
        recoveryUntil: recoveryEnd,
      ),
    ),
    build: build,
    act: (cubit) => cubit.give(_herb, petId: _worg, targetName: _worgName),
    expect: () => [
      const PotionDrinking(_herb, targetPetId: _worg, targetName: _worgName),
      PotionRefused(
        _herb,
        ItemUseFailure.petPotionRecovering,
        recoveryUntil: recoveryEnd,
        sequence: 1,
        targetPetId: _worg,
        targetName: _worgName,
      ),
    ],
  );

  blocTest<PotionCubit, PotionState>(
    'drink keeps no target (Phase 18 D-11)',
    setUp: () => stubUseItem().thenAnswer((_) async => result),
    build: build,
    act: (cubit) => cubit.drink(_herb),
    expect: () => [
      isA<PotionDrinking>()
          .having((s) => s.targetPetId, 'targetPetId', isNull)
          .having((s) => s.targetName, 'targetName', isNull),
      isA<PotionDrunk>()
          .having((s) => s.targetPetId, 'targetPetId', isNull)
          .having((s) => s.targetName, 'targetName', isNull),
    ],
    verify: (_) => verify(() => repository.useItem(_herb)).called(1),
  );

  test('a second give or drink while one is in flight is ignored '
      '(single-flight)', () async {
    final pending = Completer<UseItemResult>();
    stubUseItem().thenAnswer((_) => pending.future);
    final cubit = build();

    final first = cubit.give(_herb, petId: _worg, targetName: _worgName);
    await cubit.give('l-other', petId: _worg, targetName: _worgName);
    await cubit.drink('l-other');
    pending.complete(result);
    await first;

    verify(() => repository.useItem(_herb, petId: _worg)).called(1);
    verifyNever(
      () => repository.useItem('l-other', petId: any(named: 'petId')),
    );
    expect(
      cubit.state,
      PotionDrunk(_herb, result, targetPetId: _worg, targetName: _worgName),
    );
    await cubit.close();
  });

  test('reset returns to idle, never while drinking (D-11)', () async {
    final pending = Completer<UseItemResult>();
    stubUseItem().thenAnswer((_) => pending.future);
    final cubit = build();

    final drinking = cubit.drink(_herb);
    cubit.reset();
    expect(cubit.state, const PotionDrinking(_herb));

    pending.complete(result);
    await drinking;
    cubit.reset();
    expect(cubit.state, const PotionIdle());
    await cubit.close();
  });

  test('nothing is emitted after close (D-11)', () async {
    final pending = Completer<UseItemResult>();
    stubUseItem().thenAnswer((_) => pending.future);
    final cubit = build();
    final states = <PotionState>[];
    final subscription = cubit.stream.listen(states.add);

    final drinking = cubit.drink(_herb);
    await Future<void>.value();
    await cubit.close();
    final seenAtClose = List<PotionState>.of(states);

    pending.complete(result);
    await drinking;
    await cubit.drink(_herb);

    expect(states, seenAtClose);
    expect(cubit.state, const PotionDrinking(_herb));
    verify(() => repository.useItem(_herb)).called(1);
    await subscription.cancel();
  });
}
