import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/mocks.dart';

const beaId = 'char-bea';
const cosimoId = 'char-cosimo';
const valantarMarkerId = 'poi-valantar-marker';
const borgoMarkerId = 'poi-borgo-marker';
const resumeCardKey = 'quest-world-1';

City cityWithMarker(String id, String markerId) => City.fromJson({
  'id': id,
  'markerLocation': {
    'id': markerId,
    'location': [1.0, 2.0],
  },
});

PointOfInterest placeOf({
  required String id,
  List<String> types = const ['ruins'],
}) => PointOfInterest.fromJson(pointOfInterestJson(id: id, types: types));

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
  final beaGroup = TeleportTarget.fromCharacter(
    beaCharacter(),
    fallbackName: 'Bea',
    companionIds: const [cosimoId],
  )!;
  final ruins = placeOf(id: 'poi-ruins-1');
  final cave = placeOf(id: 'poi-forest-1', types: const ['forest']);
  final toRuins = TeleportDestination.ofPlace(ruins)!;

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.readCharacter(beaId),
    ).thenAnswer((_) async => beaCharacter());
    when(
      () => repository.listPointsOfInterest(),
    ).thenAnswer((_) async => const <PointOfInterest>[]);
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
      'keeps the companions on the target (UAT 2026-11-01)',
      build: build,
      act: (cubit) => cubit.prepare(
        characterId: beaId,
        name: 'Bea',
        companionIds: const [cosimoId],
      ),
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        TeleportActive(target: beaGroup),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'reads the character once and enters teleport mode (D-15/C3)',
      build: build,
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => [const TeleportPreparing(characterId: beaId), activeBea],
      verify: (_) => verify(() => repository.readCharacter(beaId)).called(1),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'prepare reads the character then the places and carries the inner places (D-01, D-29)',
      build: build,
      setUp: () => when(() => repository.listPointsOfInterest()).thenAnswer(
        (_) async => [
          placeOf(id: valantarMarkerId, types: const ['city']),
          ruins,
          cave,
        ],
      ),
      act: (cubit) => cubit.prepare(characterId: beaId, name: 'Bea'),
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        TeleportActive(
          target: bea,
          places: [toRuins, TeleportDestination.ofPlace(cave)!],
        ),
      ],
      verify: (_) => verifyInOrder([
        () => repository.readCharacter(beaId),
        () => repository.listPointsOfInterest(),
      ]),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a failed places read leaves the city teleport working (D-29)',
      build: build,
      setUp: () => when(
        () => repository.listPointsOfInterest(),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
      act: (cubit) async {
        await cubit.prepare(characterId: beaId, name: 'Bea');
        await cubit.teleportTo(TeleportDestination.ofCity(borgo)!);
      },
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        activeBea,
        TeleportActive(target: bea, isTeleporting: true),
        TeleportSucceeded(target: bea),
      ],
      verify: (_) => verify(
        () => repository.teleport(characterId: beaId, poiId: borgoMarkerId),
      ).called(1),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'prepare keeps the resumeCardKey on the active state (D-28)',
      build: build,
      act: (cubit) => cubit.prepare(
        characterId: beaId,
        name: 'Bea',
        resumeCardKey: resumeCardKey,
      ),
      expect: () => [
        const TeleportPreparing(characterId: beaId),
        TeleportActive(target: bea, resumeCardKey: resumeCardKey),
      ],
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
      'teleportTo an inner place sends its poiId for every participant (D-01)',
      build: build,
      seed: () => TeleportActive(target: beaGroup, places: [toRuins]),
      act: (cubit) => cubit.teleportTo(toRuins),
      expect: () => [
        TeleportActive(
          target: beaGroup,
          places: [toRuins],
          isTeleporting: true,
        ),
        TeleportSucceeded(target: beaGroup),
      ],
      verify: (_) => verifyInOrder([
        () => repository.teleport(characterId: beaId, poiId: 'poi-ruins-1'),
        () => repository.teleport(characterId: cosimoId, poiId: 'poi-ruins-1'),
      ]),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'the current place makes no call (D-01, Phase 10 C16)',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(
        TeleportDestination(
          poiId: bea.location.id,
          point: bea.location.location!,
          label: 'Rovine presso Valantar',
          isCityMarker: false,
        ),
      ),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'success carries the resumeCardKey (D-28, Pitfall 1)',
      build: build,
      seed: () => TeleportActive(target: bea, resumeCardKey: resumeCardKey),
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => [
        TeleportActive(
          target: bea,
          resumeCardKey: resumeCardKey,
          isTeleporting: true,
        ),
        TeleportSucceeded(target: bea, resumeCardKey: resumeCardKey),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a refusal keeps the places and the resumeCardKey (D-28)',
      build: build,
      setUp: () => stubTeleportFailure(InnkeeperFailure.questInProgress),
      seed: () => TeleportActive(
        target: bea,
        places: [toRuins],
        resumeCardKey: resumeCardKey,
      ),
      act: (cubit) => cubit.teleportTo(toRuins),
      expect: () => [
        TeleportActive(
          target: bea,
          places: [toRuins],
          resumeCardKey: resumeCardKey,
          isTeleporting: true,
        ),
        TeleportActive(
          target: bea,
          places: [toRuins],
          resumeCardKey: resumeCardKey,
          failure: InnkeeperFailure.questInProgress,
        ),
      ],
    );
    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop on the current city makes no call and keeps the mode (C16)',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(valantar)!),
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
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        TeleportSucceeded(target: bea),
      ],
      verify: (_) => verify(
        () => repository.teleport(characterId: beaId, poiId: borgoMarkerId),
      ).called(1),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a group drop moves the target and then every companion (UAT 2026-11-01)',
      build: build,
      seed: () => TeleportActive(target: beaGroup),
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => [
        TeleportActive(target: beaGroup, isTeleporting: true),
        TeleportSucceeded(target: beaGroup),
      ],
      verify: (_) => verifyInOrder([
        () => repository.teleport(characterId: beaId, poiId: borgoMarkerId),
        () => repository.teleport(characterId: cosimoId, poiId: borgoMarkerId),
      ]),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a companion refusal keeps the mode with the failure',
      build: build,
      setUp: () => when(
        () => repository.teleport(characterId: cosimoId, poiId: borgoMarkerId),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.questInProgress)),
      seed: () => TeleportActive(target: beaGroup),
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => [
        TeleportActive(target: beaGroup, isTeleporting: true),
        TeleportActive(
          target: beaGroup,
          failure: InnkeeperFailure.questInProgress,
        ),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a refusal keeps the mode with the failure for the chip (D-17)',
      build: build,
      setUp: () => stubTeleportFailure(InnkeeperFailure.questInProgress),
      seed: () => activeBea,
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
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
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
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
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        const TeleportIdle(),
      ],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'a drop while a teleport is in flight is ignored',
      build: build,
      seed: () => TeleportActive(target: bea, isTeleporting: true),
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
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
      act: (cubit) => cubit.teleportTo(TeleportDestination.ofCity(borgo)!),
      expect: () => <TeleportModeState>[],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );
  });

  group('cancelToPanel (UAT 2026-11-01)', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'cancel carries the resumeCardKey (D-28, Pitfall 1)',
      build: build,
      seed: () => TeleportActive(target: bea, resumeCardKey: resumeCardKey),
      act: (cubit) => cubit.cancelToPanel(),
      expect: () => [const TeleportCancelled(resumeCardKey: resumeCardKey)],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      '«Annulla» from the map leaves towards the panel',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.cancelToPanel(),
      expect: () => [const TeleportCancelled()],
      verify: (_) => verifyNever(
        () => repository.teleport(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'is ignored while the teleport is in flight',
      build: build,
      seed: () => TeleportActive(target: bea, isTeleporting: true),
      act: (cubit) => cubit.cancelToPanel(),
      expect: () => <TeleportModeState>[],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'the panel acknowledges the cancel and the mode is idle again',
      build: build,
      seed: () => const TeleportCancelled(),
      act: (cubit) => cubit.acknowledgeExit(),
      expect: () => [const TeleportIdle()],
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
      'is ignored while the teleport is in flight, the success still lands',
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
        unawaited(cubit.teleportTo(TeleportDestination.ofCity(borgo)!));
        cubit.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      expect: () => [
        TeleportActive(target: bea, isTeleporting: true),
        TeleportSucceeded(target: bea),
      ],
    );
  });

  group('acknowledgeExit', () {
    blocTest<TeleportModeCubit, TeleportModeState>(
      'ends the mode after a success',
      build: build,
      seed: () => TeleportSucceeded(target: bea),
      act: (cubit) => cubit.acknowledgeExit(),
      expect: () => [const TeleportIdle()],
    );

    blocTest<TeleportModeCubit, TeleportModeState>(
      'does nothing in any other state',
      build: build,
      seed: () => activeBea,
      act: (cubit) => cubit.acknowledgeExit(),
      expect: () => <TeleportModeState>[],
    );
  });
}
