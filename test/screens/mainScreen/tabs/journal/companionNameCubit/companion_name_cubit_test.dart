import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

const _characterId = 'c-1';
const _worg = 'pet-worg';
const _name = 'Fenrir';

void main() {
  late MockCompanionRepository repository;

  setUp(() {
    repository = MockCompanionRepository();
  });

  CompanionNameCubit build() => CompanionNameCubit(repository);

  When<Future<void>> stubRename() => when(
    () => repository.rename(
      characterId: any(named: 'characterId'),
      petId: any(named: 'petId'),
      name: any(named: 'name'),
    ),
  );

  Future<void> renameWorg(CompanionNameCubit cubit) =>
      cubit.rename(characterId: _characterId, petId: _worg, name: _name);

  test('starts idle', () {
    final cubit = build();

    expect(cubit.state, const CompanionNameIdle());
    cubit.close();
  });

  blocTest<CompanionNameCubit, CompanionNameState>(
    'rename emits Submitting → Saved (D-18, D-19)',
    setUp: () => stubRename().thenAnswer((_) async {}),
    build: build,
    act: renameWorg,
    expect: () => const [
      CompanionNameSubmitting(_worg),
      CompanionNameSaved(_worg, sequence: 1),
    ],
    verify: (_) => verify(
      () => repository.rename(
        characterId: _characterId,
        petId: _worg,
        name: _name,
      ),
    ).called(1),
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'a second rename while submitting is ignored (single-flight, D-19)',
    setUp: () => stubRename().thenAnswer((_) => Completer<void>().future),
    build: build,
    act: (cubit) {
      renameWorg(cubit);
      cubit.rename(characterId: _characterId, petId: 'pet-owl', name: 'Gufo');
    },
    expect: () => const [CompanionNameSubmitting(_worg)],
    verify: (_) => verify(
      () => repository.rename(
        characterId: any(named: 'characterId'),
        petId: any(named: 'petId'),
        name: any(named: 'name'),
      ),
    ).called(1),
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'a refused rename emits Refused with its failure and an increasing '
    'sequence (D-21, D-31)',
    setUp: () => stubRename().thenThrow(
      const PetRenameException(PetRenameFailure.nameInvalid),
    ),
    build: build,
    act: (cubit) async {
      await renameWorg(cubit);
      await renameWorg(cubit);
    },
    expect: () => const [
      CompanionNameSubmitting(_worg),
      CompanionNameRefused(_worg, PetRenameFailure.nameInvalid, sequence: 1),
      CompanionNameSubmitting(_worg),
      CompanionNameRefused(_worg, PetRenameFailure.nameInvalid, sequence: 2),
    ],
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'an unexpected error is refused as unknown (D-31)',
    setUp: () => stubRename().thenThrow(StateError('boom')),
    build: build,
    act: renameWorg,
    expect: () => const [
      CompanionNameSubmitting(_worg),
      CompanionNameRefused(_worg, PetRenameFailure.unknown, sequence: 1),
    ],
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'reset clears a refusal when the player acts again (D-21)',
    setUp: () => stubRename().thenThrow(
      const PetRenameException(PetRenameFailure.connection),
    ),
    build: build,
    act: (cubit) async {
      await renameWorg(cubit);
      cubit.reset();
    },
    expect: () => const [
      CompanionNameSubmitting(_worg),
      CompanionNameRefused(_worg, PetRenameFailure.connection, sequence: 1),
      CompanionNameIdle(),
    ],
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'reset is ignored while submitting (review lesson, D-19)',
    setUp: () => stubRename().thenAnswer((_) => Completer<void>().future),
    build: build,
    act: (cubit) {
      renameWorg(cubit);
      cubit.reset();
    },
    expect: () => const [CompanionNameSubmitting(_worg)],
  );

  blocTest<CompanionNameCubit, CompanionNameState>(
    'a rename after close is ignored',
    build: build,
    act: (cubit) async {
      await cubit.close();
      await renameWorg(cubit);
    },
    expect: () => const <CompanionNameState>[],
    verify: (_) => verifyNever(
      () => repository.rename(
        characterId: any(named: 'characterId'),
        petId: any(named: 'petId'),
        name: any(named: 'name'),
      ),
    ),
  );
}
