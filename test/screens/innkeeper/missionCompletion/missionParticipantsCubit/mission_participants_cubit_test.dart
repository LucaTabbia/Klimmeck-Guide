import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
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

final Character _aldoWithStory = Character.fromJson({
  'id': _aldo,
  'infos': {
    'name': 'Aldo',
    'background': ['Nato a Drustea.', 'Ha salvato Bosa dai predoni.'],
  },
  'status': {'title': 'adventurer'},
});

final PointOfInterest _ruinsPlace = PointOfInterest.fromJson(
  pointOfInterestJson(),
);

MissionParticipantsLoaded _loaded(
  Map<String, Character> characters, {
  bool isRereadingPositions = false,
  InnkeeperFailure? positionsFailure,
}) => MissionParticipantsLoaded(
  characters: characters,
  places: {_ruins: _ruinsPlace},
  isRereadingPositions: isRereadingPositions,
  positionsFailure: positionsFailure,
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
      'a failed read of the places loads the participants with no places (D-31)',
      setUp: () => when(
        () => repository.listPointsOfInterest(),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.timedOut)),
      build: build,
      act: (cubit) => cubit.load(const [_aldo]),
      expect: () => [
        const MissionParticipantsLoading(),
        MissionParticipantsLoaded(
          characters: {_aldo: _aldoAtRuins},
          places: const {},
        ),
      ],
    );
  });

  group('ensureLoaded', () {
    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'ensureLoaded reads the characters when nothing was read (D-02)',
      build: build,
      act: (cubit) => cubit.ensureLoaded(const [_aldo, _bea]),
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
      ],
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(1);
        verify(() => repository.readCharacter(_bea)).called(1);
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'ensureLoaded does not read again the ids already loaded (D-02)',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo, _bea]);
        await cubit.ensureLoaded(const [_bea, _aldo]);
      },
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
      'ensureLoaded does nothing while a read is running',
      build: build,
      act: (cubit) => Future.wait([
        cubit.ensureLoaded(const [_aldo]),
        cubit.ensureLoaded(const [_aldo, _bea]),
      ]),
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
      ],
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(1);
        verifyNever(() => repository.readCharacter(_bea));
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'ensureLoaded reads again for different ids',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo]);
        await cubit.ensureLoaded(const [_aldo, _bea]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
      ],
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(2);
        verify(() => repository.readCharacter(_bea)).called(1);
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'ensureLoaded reads again after a failed read',
      setUp: () => when(
        () => repository.readCharacter(_aldo),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo]);
        when(
          () => repository.readCharacter(_aldo),
        ).thenAnswer((_) async => _aldoAtRuins);
        await cubit.ensureLoaded(const [_aldo]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        const MissionParticipantsFailed(failure: InnkeeperFailure.connection),
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
      ],
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'load always reads again (retry)',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo]);
        await cubit.load(const [_aldo]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
        _loaded({_aldo: _aldoAtRuins}, isRereadingPositions: true),
        _loaded({_aldo: _aldoAtRuins}),
      ],
      verify: (_) => verify(() => repository.readCharacter(_aldo)).called(2),
    );
  });

  group('reread (WR-01)', () {
    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'reread keeps what was read on show and serves the fresh positions',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo, _bea]);
        when(
          () => repository.readCharacter(_bea),
        ).thenAnswer((_) async => _beaElsewhere);
        await cubit.reread(const [_aldo, _bea]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
        _loaded({
          _aldo: _aldoAtRuins,
          _bea: _beaAtRuins,
        }, isRereadingPositions: true),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaElsewhere}),
      ],
      verify: (_) {
        verify(() => repository.readCharacter(_aldo)).called(2);
        verify(() => repository.readCharacter(_bea)).called(2);
      },
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'reread asked while a read is running waits for it and reads again',
      build: build,
      act: (cubit) => Future.wait([
        cubit.ensureLoaded(const [_aldo]),
        cubit.reread(const [_aldo]),
      ]),
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
        _loaded({_aldo: _aldoAtRuins}, isRereadingPositions: true),
        _loaded({_aldo: _aldoAtRuins}),
      ],
      verify: (_) => verify(() => repository.readCharacter(_aldo)).called(2),
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'a failed reread keeps the stories and marks the positions as failed; '
      'load retries',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo]);
        when(
          () => repository.readCharacter(_aldo),
        ).thenThrow(const InnkeeperException(InnkeeperFailure.connection));
        await cubit.reread(const [_aldo]);
        when(
          () => repository.readCharacter(_aldo),
        ).thenAnswer((_) async => _aldoAtRuins);
        await cubit.load(const [_aldo]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
        _loaded({_aldo: _aldoAtRuins}, isRereadingPositions: true),
        _loaded({
          _aldo: _aldoAtRuins,
        }, positionsFailure: InnkeeperFailure.connection),
        _loaded({_aldo: _aldoAtRuins}, isRereadingPositions: true),
        _loaded({_aldo: _aldoAtRuins}),
      ],
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'reread with nothing read, or for other ids, is a plain read',
      build: build,
      act: (cubit) async {
        await cubit.reread(const [_aldo]);
        await cubit.reread(const [_aldo, _bea]);
      },
      expect: () => [
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins}),
        const MissionParticipantsLoading(),
        _loaded({_aldo: _aldoAtRuins, _bea: _beaAtRuins}),
      ],
    );

    blocTest<MissionParticipantsCubit, MissionParticipantsState>(
      'ensureLoaded does not read again after a failed reread: the stories '
      'are there',
      build: build,
      act: (cubit) async {
        await cubit.ensureLoaded(const [_aldo]);
        when(
          () => repository.readCharacter(_aldo),
        ).thenThrow(const InnkeeperException(InnkeeperFailure.connection));
        await cubit.reread(const [_aldo]);
        await cubit.ensureLoaded(const [_aldo]);
      },
      verify: (_) => verify(() => repository.readCharacter(_aldo)).called(2),
    );
  });

  group('loaded', () {
    test('backgroundOf gives the entries of a loaded participant and null '
        'for an unknown id (D-03)', () {
      final loaded = _loaded({_aldo: _aldoWithStory, _bea: _beaAtRuins});

      expect(loaded.backgroundOf(_aldo), [
        'Nato a Drustea.',
        'Ha salvato Bosa dai predoni.',
      ]);
      expect(loaded.backgroundOf(_bea), isEmpty);
      expect(loaded.backgroundOf('char-unknown'), isNull);
    });

    test('titleOf gives the served rank and null for an unknown id', () {
      final loaded = _loaded({_aldo: _aldoWithStory, _bea: _beaAtRuins});

      expect(loaded.titleOf(_aldo), TitleType.adventurer);
      expect(loaded.titleOf(_bea), isNull);
      expect(loaded.titleOf('char-unknown'), isNull);
    });

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

    test('the positions are unknown while they are read again and after a '
        'failed reread; the stories stay (WR-01)', () {
      final characters = {_aldo: _aldoWithStory, _bea: _beaAtRuins};
      final current = _loaded({_bea: _beaAtRuins});

      expect(current.locationIdOf(_bea), _ruins);
      expect(current.locationIdOf('char-unknown'), isNull);
      for (final stale in [
        _loaded(characters, isRereadingPositions: true),
        _loaded(characters, positionsFailure: InnkeeperFailure.connection),
      ]) {
        expect(stale.commonLocationId, isNull);
        expect(stale.locationIdOf(_bea), isNull);
        expect(stale.backgroundOf(_aldo), hasLength(2));
        expect(stale.titleOf(_aldo), TitleType.adventurer);
      }
      expect(
        _loaded({
          _bea: _beaAtRuins,
        }, isRereadingPositions: true).commonLocationId,
        isNull,
      );
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
