import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const beaId = 'char-bea';
const valantarMarkerId = 'poi-valantar-marker';
const borgoMarkerId = 'poi-borgo-marker';

City cityWithMarker(String id, String markerId) => City.fromJson({
  'id': id,
  'markerLocation': {
    'id': markerId,
    'location': [1.0, 2.0],
  },
});

Character beaCharacter({Object? sex = 'female'}) {
  final json = participantCharacterJson(
    id: beaId,
    name: 'Bea',
    locationId: valantarMarkerId,
  );
  json['infos'] = {'name': 'Bea', 'sex': sex};
  return Character.fromJson(json);
}

void main() {
  late MockInnkeeperRepository repository;
  final bea = TeleportTarget.fromCharacter(
    beaCharacter(),
    fallbackName: 'Bea',
  )!;
  final valantar = cityWithMarker('city-valantar', valantarMarkerId);
  final borgo = cityWithMarker('city-borgo', borgoMarkerId);
  final activeBea = TeleportActive(target: bea);

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.readCharacter(beaId),
    ).thenAnswer((_) async => beaCharacter());
    when(
      () => repository.teleport(
        characterId: any(named: 'characterId'),
        poiId: any(named: 'poiId'),
      ),
    ).thenAnswer((_) async {});
  });

  TeleportModeCubit build() => TeleportModeCubit(repository: repository);

  void stubTeleportFailure(InnkeeperFailure failure) => when(
    () => repository.teleport(
      characterId: any(named: 'characterId'),
      poiId: any(named: 'poiId'),
    ),
  ).thenThrow(InnkeeperException(failure));

  test('starts idle', () {
    final cubit = build();

    expect(cubit.state, const TeleportIdle());
    cubit.close();
  });

  group('prepare', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'reads the character once and enters teleport mode (D-15/C3)',
      build: build,
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => [const TeleportPreparing(characterId: beaId), activeBea],
      verify: (_) => verify(() => repository.readCharacter(beaId)).called(1),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a read failure keeps the mode off with the coded failure',
      build: build,
      setUp: () => when(
        () => repository.readCharacter(beaId),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.notFound)),
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        const TeleportPreparationFailed(
          characterId: beaId,
          failure: InnkeeperFailure.notFound,
        ),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a character without a pawn sex is malformed',
      build: build,
      setUp: () => when(
        () => repository.readCharacter(beaId),
      ).thenAnswer((_) async => beaCharacter(sex: null)),
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        const TeleportPreparationFailed(
          characterId: beaId,
          failure: InnkeeperFailure.malformed,
        ),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'is ignored while preparing',
      build: build,
      seed: () => const TeleportPreparing(characterId: beaId),
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(() => repository.readCharacter(any())),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'is ignored while the mode is active',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(() => repository.readCharacter(any())),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a read answered after cancel does not enter the mode',
      build: build,
      setUp: () {
        final pending = Completer<Character>();
        when(
          () => repository.readCharacter(beaId),
        ).thenAnswer((_) => pending.future);
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => pending.complete(beaCharacter()),
        );
      },
      act: (cubit) async {
        unawaited(cubit.prepare(characterId: beaId, name: 'Bea'));
        cubit.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        const TeleportIdle(),
      ],
    );
  });

  group('teleportTo', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop on the current city makes no call and keeps the mode (C16)',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(valantar),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop on another city teleports at once (D-16)',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        TeleportSucceeded(target: bea),
      ],
      verify: (_) => verify(
        () => repository.teleport(characterId: beaId, poiId: borgoMarkerId),
      ).called(1),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a refusal keeps the mode with the failure for the chip (D-17)',
      build: build,
      setUp: () => stubTeleportFailure(InnkeeperFailure.questInProgress),
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        TeleportActive(target: bea, failure: InnkeeperFailure.questInProgress),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a new drop clears the previous failure while in flight',
      build: build,
      seed: () => TeleportActive(
        target: bea,
        failure: InnkeeperFailure.questInProgress,
      ),
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        TeleportSucceeded(target: bea),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a lost role ends the mode',
      build: build,
      setUp: () => stubTeleportFailure(InnkeeperFailure.forbidden),
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        const TeleportIdle(),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop while a teleport is in flight is ignored',
      build: build,
      seed: () => TeleportActive(target: bea, isTeleporting: true),
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop outside the mode is ignored',
      build: build,
      act: (cubit) => cubit.teleportTo(borgo),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );
  });

  group('cancel', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'leaves the mode without calling',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.cancel(),
      expect: () => [const TeleportIdle()],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a late success after cancel emits nothing',
      build: build,
      setUp: () {
        final pending = Completer<void>();
        when(
          () => repository.teleport(
            characterId: any(named: 'characterId'),
            poiId: any(named: 'poiId'),
          ),
        ).thenAnswer((_) => pending.future);
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          pending.complete,
        );
      },
      seed: () => activeBea,
      act: (cubit) async {
        unawaited(cubit.teleportTo(borgo));
        cubit.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        const TeleportIdle(),
      ],
    );
  });

  group('acknowledgeSuccess', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'ends the mode after a success',
      build: build,
      seed: () => TeleportSucceeded(target: bea),
      act: (cubit) => cubit.acknowledgeSuccess(),
      expect: () => [const TeleportIdle()],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'does nothing in any other state',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.acknowledgeSuccess(),
      expect: () => <TeleportModeState>[],
    );
  });
}
