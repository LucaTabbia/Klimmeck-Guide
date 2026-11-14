import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/mocks.dart';

const String _pendingQuestId = 'pq-world-1';

MissionEnemy _enemy(String id, String name, {int xp = 30}) =>
    MissionEnemy.tryFromJson(missionEnemyJson(id: id, name: name, xp: xp))!;

final MissionEnemy _wolf = _enemy('enemy-wolf', 'Lupo');
final MissionEnemy _goblin = _enemy('enemy-goblin', 'Goblin');
final MissionEnemy _werewolf = _enemy('enemy-werewolf', 'Lupo mannaro');
final MissionEnemy _dragon = _enemy('enemy-dragon', 'Drago', xp: 9000);

/// Ordine del BE, non alfabetico né per xp (D-19).
final List<MissionEnemy> _defaultList = [_wolf, _goblin, _werewolf];
final List<MissionEnemy> _bestiary = [_dragon, _wolf, _goblin, _werewolf];

void main() {
  late MockInnkeeperRepository repository;

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: false),
    ).thenAnswer((_) async => _defaultList);
    when(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: true),
    ).thenAnswer((_) async => _bestiary);
  });

  MissionEnemiesCubit build() => MissionEnemiesCubit(
    repository: repository,
    pendingQuestId: _pendingQuestId,
  );

  test('starts empty with the default list', () {
    expect(build().state, const MissionEnemiesState());
  });

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'load keeps the served order (D-19)',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const MissionEnemiesState(isLoading: true),
      MissionEnemiesState(enemies: _defaultList),
    ],
    verify: (cubit) {
      expect(cubit.state.visible, [_wolf, _goblin, _werewolf]);
      verify(
        () => repository.listMissionEnemies(_pendingQuestId, showAll: false),
      ).called(1);
    },
  );

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'Mostra tutti refetches with showAll true (D-03)',
    build: build,
    seed: () => MissionEnemiesState(enemies: _defaultList),
    act: (cubit) => cubit.setShowAll(true),
    expect: () => [
      MissionEnemiesState(
        enemies: _defaultList,
        showAll: true,
        isLoading: true,
      ),
      MissionEnemiesState(enemies: _bestiary, showAll: true),
    ],
    verify: (_) => verify(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: true),
    ).called(1),
  );

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'turning Mostra tutti off refetches the default list (D-03)',
    build: build,
    seed: () => MissionEnemiesState(enemies: _bestiary, showAll: true),
    act: (cubit) => cubit.setShowAll(false),
    expect: () => [
      MissionEnemiesState(enemies: _bestiary, isLoading: true),
      MissionEnemiesState(enemies: _defaultList),
    ],
    verify: (_) => verify(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: false),
    ).called(1),
  );

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'the same toggle again sends nothing',
    build: build,
    seed: () => MissionEnemiesState(enemies: _bestiary, showAll: true),
    act: (cubit) => cubit.setShowAll(true),
    expect: () => <MissionEnemiesState>[],
    verify: (_) => verifyNever(
      () =>
          repository.listMissionEnemies(any(), showAll: any(named: 'showAll')),
    ),
  );

  test('a list arriving after the toggle changed again is dropped', () async {
    final slowBestiary = Completer<List<MissionEnemy>>();
    when(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: true),
    ).thenAnswer((_) => slowBestiary.future);
    final cubit = build();
    await cubit.load();

    final showingAll = cubit.setShowAll(true);
    await cubit.setShowAll(false);
    slowBestiary.complete(_bestiary);
    await showingAll;

    expect(cubit.state, MissionEnemiesState(enemies: _defaultList));
    await cubit.close();
  });

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'the name search filters only the display, case-insensitive (D-03)',
    build: build,
    seed: () => MissionEnemiesState(enemies: _defaultList),
    act: (cubit) => cubit.setQuery('  LUPO '),
    verify: (cubit) {
      expect(cubit.state.query, '  LUPO ');
      expect(cubit.state.visible, [_wolf, _werewolf]);
      expect(cubit.state.enemies, _defaultList);
      verifyNever(
        () => repository.listMissionEnemies(
          any(),
          showAll: any(named: 'showAll'),
        ),
      );
    },
  );

  test('an empty search shows the whole served list', () {
    final state = MissionEnemiesState(enemies: _defaultList, query: '   ');

    expect(state.visible, _defaultList);
  });

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'a failure keeps the last list with the failure',
    setUp: () => when(
      () => repository.listMissionEnemies(_pendingQuestId, showAll: true),
    ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
    build: build,
    seed: () => MissionEnemiesState(enemies: _defaultList),
    act: (cubit) => cubit.setShowAll(true),
    expect: () => [
      MissionEnemiesState(
        enemies: _defaultList,
        showAll: true,
        isLoading: true,
      ),
      MissionEnemiesState(
        enemies: _defaultList,
        showAll: true,
        failure: InnkeeperFailure.connection,
      ),
    ],
  );

  blocTest<MissionEnemiesCubit, MissionEnemiesState>(
    'a new load clears the failure',
    build: build,
    seed: () => MissionEnemiesState(
      enemies: _defaultList,
      failure: InnkeeperFailure.connection,
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      MissionEnemiesState(enemies: _defaultList, isLoading: true),
      MissionEnemiesState(enemies: _defaultList),
    ],
  );
}
