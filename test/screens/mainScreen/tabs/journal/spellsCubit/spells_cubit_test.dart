import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
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
}
