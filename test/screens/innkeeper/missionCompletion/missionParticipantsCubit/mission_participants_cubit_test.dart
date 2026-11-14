import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/mocks.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _ruins = 'poi-ruins-1';

final Character _aldoAtRuins = Character.fromJson(
  participantCharacterJson(locationId: _ruins),
);
final Character _beaAtRuins = Character.fromJson(
  participantCharacterJson(id: _bea, name: 'Bea', locationId: _ruins),
);
final Character _beaElsewhere = Character.fromJson(
  participantCharacterJson(id: _bea, name: 'Bea'),
);

final PointOfInterest _ruinsPlace = PointOfInterest.fromJson(
  pointOfInterestJson(),
);

MissionParticipantsLoaded _loaded(Map<String, Character> characters) =>
    MissionParticipantsLoaded(
      characters: characters,
      places: {_ruins: _ruinsPlace},
    );

void main() {
  late MockInnkeeperRepository repository;

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.readCharacter(_aldo),
    ).thenAnswer((_) async => _aldoAtRuins);
    when(
      () => repository.readCharacter(_bea),
    ).thenAnswer((_) async => _beaAtRuins);
    when(
      () => repository.listPointsOfInterest(),
    ).thenAnswer((_) async => [_ruinsPlace]);
  });

  MissionParticipantsCubit build() =>
      MissionParticipantsCubit(repository: repository);

  test('starts idle', () {
    expect(build().state, const MissionParticipantsIdle());
  });

  group('load', () {
    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'loads every participant and the places once (D-29)',
      build: build,
      act: (cubit) => cubit.load(const [_aldo, _bea]),
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
      ],
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(1);
        verify(() => repository.readCharacter(_bea)).called(1);
        verify(() => repository.listPointsOfInterest()).called(1);
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'a second load while loading is ignored',
      build: build,
      act: (cubit) => Future.wait([
        cubit.load(const [_aldo]),
        cubit.load(const [_aldo]),
      ]),
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(1);
        verify(() => repository.listPointsOfInterest()).called(1);
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'a failed read is failed; load again retries',
      setUp: () => when(
        () => repository.readCharacter(_bea),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
      build: build,
      act: (cubit) async {
        await cubit.load(const [_aldo, _bea]);
        when(
          () => repository.readCharacter(_bea),
        ).thenAnswer((_) async => _beaAtRuins);
        await cubit.load(const [_aldo, _bea]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        const MissionParticipantsFailed(failure: InnkeeperFailure.connection),
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
      ],
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'a failed read of the places is failed',
      setUp: () => when(
        () => repository.listPointsOfInterest(),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.timedOut)),
      build: build,
      act: (cubit) => cubit.load(const [_aldo]),
      expect: () => [
        const MissionParticipantsLoading(),
        const MissionParticipantsFailed(failure: InnkeeperFailure.timedOut),
      ],
    );
  });

  group('loaded', () {
    test('commonLocationId is the shared place, null for a split group '
        '(D-01)', () {
      expect(
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}).commonLocationId,
        _ruins,
      );
      expect(
        _loaded({_aldo: _aldoAtRuins, _bea: _beaElsewhere}).commonLocationId,
        isNull,
      );
      expect(_loaded({}).commonLocationId, isNull);
    });

    test('placeLabelFor names an inner place type presso city (D-29)', () {
      final loaded = _loaded({_aldo: _aldoAtRuins});

      expect(loaded.placeLabelFor(_ruins), 'Rovine presso Talmvere');
      expect(loaded.placeLabelFor('poi-unknown'), '');
      expect(loaded.placeLabelFor(null), '');
    });

    test('itemNameOf and spellNameOf read names from the character, never '
        'bounds (rule 4)', () {
      final loaded = _loaded({_aldo: _aldoAtRuins});

      expect(loaded.itemNameOf(_aldo, potionItemId), 'Pozione di cura');
      expect(loaded.itemNameOf(_aldo, 'loot-unknown'), isNull);
      expect(loaded.itemNameOf(_bea, potionItemId), isNull);
      expect(loaded.spellNameOf(_aldo, fireballSpellId), 'Palla di fuoco');
      expect(loaded.spellNameOf(_aldo, 'spell-unknown'), isNull);
      expect(loaded.spellNameOf(_bea, fireballSpellId), isNull);
    });
  });
}
