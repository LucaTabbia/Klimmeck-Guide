import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/companion_repository.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const _horse = 'pet-horse';
const _camel = 'pet-camel';

Character _character({String? equipped}) => Character.fromJson({
  'id': 'c-1',
  'assets': {
    'pet': equipped == null ? null : petJson(id: equipped),
    'ownedPets': [petJson(id: _horse), petJson(id: _camel, name: 'Cammello')],
  },
});

const _pendingEquip = CompanionState(
  pending: PendingCompanion(petId: _horse, operation: CompanionOperation.equip),
);

void main() {
  late MockCompanionRepository repository;
  late List<Completer<void>> calls;

  setUp(() {
    repository = MockCompanionRepository();
    calls = [];
    Future<void> nextCall(Invocation _) {
      final completer = Completer<void>();
      calls.add(completer);
      return completer.future;
    }

    when(
      () => repository.equip(
        characterId: any(named: 'characterId'),
        petId: any(named: 'petId'),
      ),
    ).thenAnswer(nextCall);
    when(
      () => repository.unequip(characterId: any(named: 'characterId')),
    ).thenAnswer(nextCall);
  });

  CompanionCubit build() => CompanionCubit(repository);

  (CompanionCubit, List<CompanionState>) start() {
    final cubit = build();
    final states = <CompanionState>[];
    cubit.stream.listen(states.add);
    return (cubit, states);
  }

  CompanionState outcomeState(
    CompanionOutcomeKind kind, {
    PetEquipFailure? failure,
    int sequence = 1,
  }) => CompanionState(
    outcome: CompanionOutcome(
      sequence: sequence,
      petId: _horse,
      operation: CompanionOperation.equip,
      kind: kind,
      failure: failure,
    ),
  );

  test('settles on the same 15 s as the repository', () {
    expect(
      CompanionCubit.defaultSettleTimeout,
      CompanionRepository.defaultTimeout,
    );
    expect(CompanionCubit.defaultSettleTimeout, const Duration(seconds: 15));
  });

  test('starts with no pending operation and no outcome', () {
    final cubit = build();
    expect(cubit.state, const CompanionState());
    expect(cubit.state.pending, isNull);
    expect(cubit.state.outcome, isNull);
    cubit.close();
  });

  group('optimistic slot (D-10)', () {
    blocTest<CompanionCubit, CompanionState>(
      'equip shows the pet at once and calls the repository (D-10)',
      build: build,
      act: (cubit) {
        final character = _character();
        expect(cubit.toggle(character, _horse), CompanionToggleIntent.equip);
        expect(cubit.state.displayedPetId(character), _horse);
      },
      expect: () => const [_pendingEquip],
      verify: (_) => verify(
        () => repository.equip(characterId: 'c-1', petId: _horse),
      ).called(1),
    );

    blocTest<CompanionCubit, CompanionState>(
      'tapping the displayed pet unequips it at once (D-10)',
      build: build,
      act: (cubit) {
        final character = _character(equipped: _horse);
        expect(cubit.toggle(character, _horse), CompanionToggleIntent.unequip);
        expect(cubit.state.displayedPetId(character), isNull);
      },
      expect: () => const [
        CompanionState(
          pending: PendingCompanion(
            petId: _horse,
            operation: CompanionOperation.unequip,
          ),
        ),
      ],
      verify: (_) =>
          verify(() => repository.unequip(characterId: 'c-1')).called(1),
    );

    blocTest<CompanionCubit, CompanionState>(
      'tapping another owned pet replaces the equipped one (BE single slot)',
      build: build,
      act: (cubit) {
        final character = _character(equipped: _horse);
        expect(cubit.toggle(character, _camel), CompanionToggleIntent.equip);
        expect(cubit.state.displayedPetId(character), _camel);
      },
      expect: () => const [
        CompanionState(
          pending: PendingCompanion(
            petId: _camel,
            operation: CompanionOperation.equip,
          ),
        ),
      ],
      verify: (_) => verify(
        () => repository.equip(characterId: 'c-1', petId: _camel),
      ).called(1),
    );

    test(
      'sync settles the equip when characterUpdated shows the pet (D-10)',
      () {
        fakeAsync((async) {
          final (cubit, states) = start();
          cubit.toggle(_character(), _horse);
          calls.single.complete();
          async.flushMicrotasks();
          expect(cubit.state, _pendingEquip);

          cubit.sync(_character(equipped: _horse));
          async.flushMicrotasks();

          expect(states, [_pendingEquip, const CompanionState()]);
          expect(cubit.state.outcome, isNull);
          expect(async.pendingTimers, isEmpty);
          cubit.close();
        });
      },
    );

    test('a response arriving after characterUpdated settles at once', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _horse);
        cubit.sync(_character(equipped: _horse));
        async.flushMicrotasks();
        expect(states, [_pendingEquip, const CompanionState()]);

        calls.single.complete();
        async.flushMicrotasks();

        expect(states, [_pendingEquip, const CompanionState()]);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('a refusal rolls back and yields a failed outcome with its failure '
        '(D-06)', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _horse);
        calls.single.completeError(
          const PetEquipException(PetEquipFailure.notOwned),
        );
        async.flushMicrotasks();

        expect(cubit.state.pending, isNull);
        expect(cubit.state.outcome?.kind, CompanionOutcomeKind.failed);
        expect(cubit.state.outcome?.failure, PetEquipFailure.notOwned);
        expect(states, [
          _pendingEquip,
          outcomeState(
            CompanionOutcomeKind.failed,
            failure: PetEquipFailure.notOwned,
          ),
        ]);
        expect(cubit.state.displayedPetId(_character()), isNull);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });
  });

  group('settle timer (D-10)', () {
    test('a success without characterUpdated closes by timeout as '
        'settledByTimeout', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _horse);
        calls.single.complete();
        async.elapse(CompanionCubit.defaultSettleTimeout);

        expect(states, [
          _pendingEquip,
          outcomeState(CompanionOutcomeKind.settledByTimeout),
        ]);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('no answer within the settle timeout fails with timedOut', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _horse);
        async.elapse(CompanionCubit.defaultSettleTimeout);
        expect(states, [
          _pendingEquip,
          outcomeState(
            CompanionOutcomeKind.failed,
            failure: PetEquipFailure.timedOut,
          ),
        ]);

        calls.single.complete();
        async.flushMicrotasks();

        expect(states, hasLength(2));
        cubit.close();
      });
    });
  });

  blocTest<CompanionCubit, CompanionState>(
    'a tap while an operation is pending is ignored',
    build: build,
    act: (cubit) {
      cubit.toggle(_character(), _horse);
      expect(
        cubit.toggle(_character(), _camel),
        CompanionToggleIntent.ignoredPending,
      );
    },
    expect: () => const [_pendingEquip],
    verify: (_) {
      verify(
        () => repository.equip(
          characterId: any(named: 'characterId'),
          petId: any(named: 'petId'),
        ),
      ).called(1);
      verifyNever(
        () => repository.unequip(characterId: any(named: 'characterId')),
      );
    },
  );

  test('two identical outcomes in a row are distinct (sequence)', () {
    fakeAsync((async) {
      final (cubit, states) = start();
      for (var i = 0; i < 2; i++) {
        cubit.toggle(_character(), _horse);
        async.flushMicrotasks();
        calls.last.completeError(
          const PetEquipException(PetEquipFailure.forbidden),
        );
        async.flushMicrotasks();
      }

      final outcomes = [
        for (final state in states)
          if (state.outcome case final outcome?) outcome,
      ];
      expect(outcomes.map((outcome) => outcome.sequence).toSet(), {1, 2});
      expect(
        states.last,
        outcomeState(
          CompanionOutcomeKind.failed,
          failure: PetEquipFailure.forbidden,
          sequence: 2,
        ),
      );
      cubit.close();
    });
  });

  test('close cancels the timer and drops a late response', () {
    fakeAsync((async) {
      final (cubit, states) = start();
      cubit.toggle(_character(), _horse);
      async.flushMicrotasks();
      cubit.close();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);

      calls.single.completeError(
        const PetEquipException(PetEquipFailure.forbidden),
      );
      async.elapse(CompanionCubit.defaultSettleTimeout);

      expect(states, [_pendingEquip]);
      expect(cubit.isClosed, isTrue);
    });
  });
}
