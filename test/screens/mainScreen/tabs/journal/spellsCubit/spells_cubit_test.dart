import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const _spellA = 'spell-a';
const _spellB = 'spell-b';

Character _character({
  int maxActiveSpells = 1,
  List<String> active = const [],
}) => spellbookCharacter(
  maxActiveSpells: maxActiveSpells,
  spells: [
    spellJson(id: _spellA),
    spellJson(id: _spellB),
  ],
  activeSpells: [for (final id in active) activeSpellJson(spellId: id)],
);

void main() {
  late MockSpellsRepository repository;
  late List<Completer<void>> calls;

  setUp(() {
    repository = MockSpellsRepository();
    calls = [];
    Future<void> nextCall(Invocation _) {
      final completer = Completer<void>();
      calls.add(completer);
      return completer.future;
    }

    when(
      () => repository.equip(
        characterId: any(named: 'characterId'),
        spellId: any(named: 'spellId'),
      ),
    ).thenAnswer(nextCall);
    when(
      () => repository.unequip(
        characterId: any(named: 'characterId'),
        spellId: any(named: 'spellId'),
      ),
    ).thenAnswer(nextCall);
  });

  SpellsCubit build() => SpellsCubit(repository);

  void verifyNoEquip() => verifyNever(
    () => repository.equip(
      characterId: any(named: 'characterId'),
      spellId: any(named: 'spellId'),
    ),
  );

  group('toggle and sync', () {
    test('starts empty', () {
      final cubit = build();
      expect(cubit.state, const SpellsState());
      cubit.close();
    });

    blocTest<SpellsCubit, SpellsState>(
      'an allowed equip becomes pending and calls the repository once',
      build: build,
      act: (cubit) =>
          expect(cubit.toggle(_character(), _spellA), SpellToggleIntent.equip),
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.equip}),
      ],
      verify: (_) => verify(
        () => repository.equip(characterId: 'c-1', spellId: _spellA),
      ).called(1),
    );

    blocTest<SpellsCubit, SpellsState>(
      'a tap on a pending spell is ignored',
      build: build,
      seed: () => const SpellsState(pending: {_spellA: SpellOperation.equip}),
      act: (cubit) => expect(
        cubit.toggle(_character(), _spellA),
        SpellToggleIntent.ignoredPending,
      ),
      expect: () => const <SpellsState>[],
      verify: (_) => verifyNoEquip(),
    );

    blocTest<SpellsCubit, SpellsState>(
      'a second tap while pending emits nothing and calls nothing more',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(), _spellA);
        expect(
          cubit.toggle(_character(), _spellA),
          SpellToggleIntent.ignoredPending,
        );
      },
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.equip}),
      ],
      verify: (_) => verify(
        () => repository.equip(characterId: 'c-1', spellId: _spellA),
      ).called(1),
    );

    blocTest<SpellsCubit, SpellsState>(
      'slots full by a pending equip blocks without calling the repository',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(), _spellA);
        expect(
          cubit.toggle(_character(), _spellB),
          SpellToggleIntent.blockedSlotsFull,
        );
      },
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.equip}),
        SpellsState(
          pending: {_spellA: SpellOperation.equip},
          outcome: SpellOutcome(
            sequence: 1,
            spellId: _spellB,
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.blockedSlotsFull,
          ),
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.equip(
          characterId: any(named: 'characterId'),
          spellId: _spellB,
        ),
      ),
    );

    blocTest<SpellsCubit, SpellsState>(
      'no slots blocks with a blockedNoSlots outcome',
      build: build,
      act: (cubit) => expect(
        cubit.toggle(_character(maxActiveSpells: 0), _spellA),
        SpellToggleIntent.blockedNoSlots,
      ),
      expect: () => const [
        SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: _spellA,
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.blockedNoSlots,
          ),
        ),
      ],
      verify: (_) => verifyNoEquip(),
    );

    blocTest<SpellsCubit, SpellsState>(
      'a tap on an active spell unequips it',
      build: build,
      act: (cubit) => expect(
        cubit.toggle(_character(active: [_spellA]), _spellA),
        SpellToggleIntent.unequip,
      ),
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.unequip}),
      ],
      verify: (_) => verify(
        () => repository.unequip(characterId: 'c-1', spellId: _spellA),
      ).called(1),
    );

    blocTest<SpellsCubit, SpellsState>(
      'sync with the equip applied clears the pending equip',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(), _spellA);
        cubit.sync(_character(active: [_spellA]));
      },
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.equip}),
        SpellsState(),
      ],
    );

    blocTest<SpellsCubit, SpellsState>(
      'sync keeps the last outcome while clearing',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(maxActiveSpells: 2), _spellA);
        cubit.toggle(_character(maxActiveSpells: 0), _spellB);
        cubit.sync(_character(maxActiveSpells: 2, active: [_spellA]));
      },
      skip: 2,
      expect: () => const [
        SpellsState(
          outcome: SpellOutcome(
            sequence: 1,
            spellId: _spellB,
            operation: SpellOperation.equip,
            kind: SpellOutcomeKind.blockedNoSlots,
          ),
        ),
      ],
    );

    blocTest<SpellsCubit, SpellsState>(
      'sync without the spell clears the pending unequip',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(active: [_spellA]), _spellA);
        cubit.sync(_character());
      },
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.unequip}),
        SpellsState(),
      ],
    );

    blocTest<SpellsCubit, SpellsState>(
      'sync of a non-matching character emits nothing',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(), _spellA);
        cubit.sync(_character());
      },
      expect: () => const [
        SpellsState(pending: {_spellA: SpellOperation.equip}),
      ],
    );

    blocTest<SpellsCubit, SpellsState>(
      'sync with nothing pending emits nothing',
      build: build,
      act: (cubit) => cubit.sync(_character(active: [_spellA])),
      expect: () => const <SpellsState>[],
    );

    blocTest<SpellsCubit, SpellsState>(
      'two identical blocked taps give distinct outcomes',
      build: build,
      act: (cubit) {
        cubit.toggle(_character(maxActiveSpells: 0), _spellA);
        cubit.toggle(_character(maxActiveSpells: 0), _spellA);
      },
      expect: () => [
        for (final sequence in [1, 2])
          SpellsState(
            outcome: SpellOutcome(
              sequence: sequence,
              spellId: _spellA,
              operation: SpellOperation.equip,
              kind: SpellOutcomeKind.blockedNoSlots,
            ),
          ),
      ],
    );

    blocTest<SpellsCubit, SpellsState>(
      'an unknown spell id is ignored',
      build: build,
      act: (cubit) => expect(
        cubit.toggle(_character(), 'spell-x'),
        SpellToggleIntent.ignoredUnknown,
      ),
      expect: () => const <SpellsState>[],
      verify: (_) => verifyNoEquip(),
    );
  });

  group('repository outcomes and settle timer', () {
    const pendingA = SpellsState(pending: {_spellA: SpellOperation.equip});

    (SpellsCubit, List<SpellsState>) start() {
      final cubit = build();
      final states = <SpellsState>[];
      cubit.stream.listen(states.add);
      return (cubit, states);
    }

    SpellsState failedA(
      SpellEquipFailure failure, {
      SpellOperation operation = SpellOperation.equip,
      int sequence = 1,
    }) => SpellsState(
      outcome: SpellOutcome(
        sequence: sequence,
        spellId: _spellA,
        operation: operation,
        kind: SpellOutcomeKind.failed,
        failure: failure,
      ),
    );

    test('a success waits for the matching sync, with no outcome', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        calls.single.complete();
        async.flushMicrotasks();
        expect(cubit.state, pendingA);

        cubit.sync(_character(active: [_spellA]));
        async.flushMicrotasks();

        expect(states, [pendingA, const SpellsState()]);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('a success that finds the snapshot already matching clears', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        cubit.sync(_character(active: [_spellA]));
        async.flushMicrotasks();
        expect(states, [pendingA, const SpellsState()]);

        calls.single.complete();
        async.flushMicrotasks();

        expect(states, [pendingA, const SpellsState()]);
        cubit.close();
      });
    });

    test('a cleared operation emits nothing on late success or timer', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        cubit.sync(_character(active: [_spellA]));
        calls.single.complete();
        async.elapse(SpellsCubit.defaultSettleTimeout);

        expect(states, [pendingA, const SpellsState()]);
        cubit.close();
      });
    });

    test('an equip failure clears and emits the outcome in one state', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        calls.single.completeError(
          const SpellEquipException(SpellEquipFailure.slotsFull),
        );
        async.flushMicrotasks();

        expect(states, [pendingA, failedA(SpellEquipFailure.slotsFull)]);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('an unequip failure carries the unequip operation', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(active: [_spellA]), _spellA);
        calls.single.completeError(
          const SpellEquipException(SpellEquipFailure.notActive),
        );
        async.flushMicrotasks();

        expect(
          states.last,
          failedA(
            SpellEquipFailure.notActive,
            operation: SpellOperation.unequip,
          ),
        );
        cubit.close();
      });
    });

    test('a non-domain error is treated as unknown', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        calls.single.completeError(StateError('boom'));
        async.flushMicrotasks();

        expect(states.last, failedA(SpellEquipFailure.unknown));
        cubit.close();
      });
    });

    for (final lateAnswer in ['success', 'failure']) {
      test('in flight at the timeout fails as timedOut, late $lateAnswer '
          'ignored', () {
        fakeAsync((async) {
          final (cubit, states) = start();
          cubit.toggle(_character(), _spellA);
          async.elapse(SpellsCubit.defaultSettleTimeout);
          expect(states, [pendingA, failedA(SpellEquipFailure.timedOut)]);

          if (lateAnswer == 'success') {
            calls.single.complete();
          } else {
            calls.single.completeError(
              const SpellEquipException(SpellEquipFailure.slotsFull),
            );
          }
          async.flushMicrotasks();

          expect(states, [pendingA, failedA(SpellEquipFailure.timedOut)]);
          cubit.close();
        });
      });
    }

    test('a success still unmatched at the timeout clears with a realign '
        'outcome (WR-01)', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(active: [_spellB]), _spellB);
        calls.single.complete();
        async.elapse(SpellsCubit.defaultSettleTimeout);

        expect(states, [
          const SpellsState(pending: {_spellB: SpellOperation.unequip}),
          const SpellsState(
            outcome: SpellOutcome(
              sequence: 1,
              spellId: _spellB,
              operation: SpellOperation.unequip,
              kind: SpellOutcomeKind.settledByTimeout,
            ),
          ),
        ]);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('a late matching sync after the realign outcome emits nothing', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        calls.single.complete();
        async.elapse(SpellsCubit.defaultSettleTimeout);
        final settled = states.length;

        cubit.sync(_character(active: [_spellA]));
        async.flushMicrotasks();

        expect(states, hasLength(settled));
        cubit.close();
      });
    });

    test('a new toggle after a timeout is a new operation', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        async.elapse(SpellsCubit.defaultSettleTimeout);

        expect(cubit.toggle(_character(), _spellA), SpellToggleIntent.equip);
        calls.first.complete();
        calls.last.completeError(
          const SpellEquipException(SpellEquipFailure.slotsFull),
        );
        async.flushMicrotasks();

        expect(states, [
          pendingA,
          failedA(SpellEquipFailure.timedOut),
          pendingA.copyWith(
            outcome: failedA(SpellEquipFailure.timedOut).outcome,
          ),
          failedA(SpellEquipFailure.slotsFull, sequence: 2),
        ]);
        cubit.close();
      });
    });

    test('close cancels the timers and ignores late answers', () {
      fakeAsync((async) {
        final (cubit, states) = start();
        cubit.toggle(_character(), _spellA);
        cubit.close();
        async.flushMicrotasks();
        expect(async.pendingTimers, isEmpty);

        calls.single.completeError(
          const SpellEquipException(SpellEquipFailure.slotsFull),
        );
        async.flushMicrotasks();

        expect(states, [pendingA]);
      });
    });
  });
}
