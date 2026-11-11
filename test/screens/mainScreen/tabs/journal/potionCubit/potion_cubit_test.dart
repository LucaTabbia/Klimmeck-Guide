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

void main() {
  late MockItemUseRepository repository;
  final result = UseItemResult.fromJson(useItemResultJson());
  final recoveryEnd = DateTime.utc(2026, 10, 27, 10, 30);

  setUp(() {
    repository = MockItemUseRepository();
  });

  PotionCubit build() => PotionCubit(repository);

  When<Future<UseItemResult>> stubUseItem() =>
      when(() => repository.useItem(any()));

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
