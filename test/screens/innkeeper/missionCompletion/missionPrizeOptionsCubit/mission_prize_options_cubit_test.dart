import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/mocks.dart';

const String _pendingQuestId = 'pq-world-1';
const String _aldo = 'char-aldo';
const String _bea = 'char-bea';

final MissionPrizeOptions _aldoOptions = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(),
)!;
final MissionPrizeOptions _beaOptions = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(character: _bea, title: 'mage', maxRarity: 'epic'),
)!;

void main() {
  late MockInnkeeperRepository repository;

  void stubOptions(String characterId, MissionPrizeOptions options) => when(
    () => repository.readMissionPrizeOptions(
      pendingQuestId: _pendingQuestId,
      characterId: characterId,
    ),
  ).thenAnswer((_) async => options);

  setUp(() {
    repository = MockInnkeeperRepository();
    stubOptions(_aldo, _aldoOptions);
    stubOptions(_bea, _beaOptions);
  });

  MissionPrizeOptionsCubit build() => MissionPrizeOptionsCubit(
    repository: repository,
    pendingQuestId: _pendingQuestId,
  );

  test('starts with nothing read', () {
    expect(build().state, const MissionPrizeOptionsState());
  });

  blocTest<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
    'loadFor reads one character once (D-22)',
    build: build,
    act: (cubit) async {
      await cubit.loadFor(_aldo);
      await cubit.loadFor(_aldo);
    },
    expect: () => [
      const MissionPrizeOptionsState(loading: {_aldo}),
      MissionPrizeOptionsState(options: {_aldo: _aldoOptions}),
    ],
    verify: (_) => verify(
      () => repository.readMissionPrizeOptions(
        pendingQuestId: _pendingQuestId,
        characterId: _aldo,
      ),
    ).called(1),
  );

  blocTest<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
    'a read already in flight is not sent again',
    build: build,
    act: (cubit) => Future.wait([cubit.loadFor(_aldo), cubit.loadFor(_aldo)]),
    verify: (_) => verify(
      () => repository.readMissionPrizeOptions(
        pendingQuestId: _pendingQuestId,
        characterId: _aldo,
      ),
    ).called(1),
  );

  blocTest<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
    'loadAll reads every participant',
    build: build,
    act: (cubit) => cubit.loadAll(const [_aldo, _bea]),
    verify: (cubit) {
      expect(cubit.state.options, {_aldo: _aldoOptions, _bea: _beaOptions});
      expect(cubit.state.loading, isEmpty);
      for (final characterId in [_aldo, _bea]) {
        verify(
          () => repository.readMissionPrizeOptions(
            pendingQuestId: _pendingQuestId,
            characterId: characterId,
          ),
        ).called(1);
      }
    },
  );

  blocTest<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
    'the served catalogue is kept as served (D-07, rule 4)',
    build: build,
    act: (cubit) => cubit.loadFor(_bea),
    verify: (cubit) => expect(cubit.state.options[_bea], same(_beaOptions)),
  );

  blocTest<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
    'a failure can be retried',
    setUp: () => when(
      () => repository.readMissionPrizeOptions(
        pendingQuestId: _pendingQuestId,
        characterId: _aldo,
      ),
    ).thenThrow(const InnkeeperException(InnkeeperFailure.forbidden)),
    build: build,
    act: (cubit) async {
      await cubit.loadFor(_aldo);
      stubOptions(_aldo, _aldoOptions);
      await cubit.loadFor(_aldo);
    },
    expect: () => [
      const MissionPrizeOptionsState(loading: {_aldo}),
      const MissionPrizeOptionsState(
        failures: {_aldo: InnkeeperFailure.forbidden},
      ),
      const MissionPrizeOptionsState(loading: {_aldo}),
      MissionPrizeOptionsState(options: {_aldo: _aldoOptions}),
    ],
  );
}
