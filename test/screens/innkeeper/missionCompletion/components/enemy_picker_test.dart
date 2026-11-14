import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/enemy_picker.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

final MissionEnemy _wolf = MissionEnemy.tryFromJson(missionEnemyJson())!;
final MissionEnemy _goblin = MissionEnemy.tryFromJson(
  missionEnemyJson(id: 'enemy-goblin', name: 'Goblin', xp: 20, lifePoints: 60),
)!;
final MissionEnemy _dragon = MissionEnemy.tryFromJson(
  missionEnemyJson(
    id: 'enemy-dragon',
    name: 'Drago antico',
    xp: 900,
    lifePoints: 5000,
    legendary: true,
  ),
)!;

void main() {
  late MockMissionEnemiesCubit enemiesCubit;
  late List<MissionEnemy> picks;

  setUp(() {
    enemiesCubit = MockMissionEnemiesCubit();
    picks = [];
    when(() => enemiesCubit.setShowAll(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPicker(
    WidgetTester tester,
    MissionEnemiesState state,
  ) async {
    useLandscapePhone(tester);
    whenListen(
      enemiesCubit,
      const Stream<MissionEnemiesState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BlocProvider<MissionEnemiesCubit>.value(
            value: enemiesCubit,
            child: EnemyPicker(onPick: picks.add),
          ),
        ),
      ),
    );
  }

  testWidgets('lists the served enemies in served order (D-19)', (
    tester,
  ) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_goblin, _wolf]));

    final goblinTop = tester
        .getTopLeft(find.byKey(EnemyPicker.enemyKeyFor('enemy-goblin')))
        .dy;
    final wolfTop = tester
        .getTopLeft(find.byKey(EnemyPicker.enemyKeyFor('enemy-wolf')))
        .dy;
    expect(goblinTop, lessThan(wolfTop));
    expect(find.text('PE 20 · PV 60'), findsOneWidget);
    expect(find.text('PE 30 · PV 120'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(EnemyPicker.enemyKeyFor('enemy-wolf')),
        matching: find.byType(EnemyPortrait),
      ),
      findsOneWidget,
    );
  });

  testWidgets('typing in «Cerca» sets the name query (D-03)', (tester) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_wolf]));

    await tester.enterText(find.byKey(EnemyPicker.searchKey), 'lu');

    verify(() => enemiesCubit.setQuery('lu')).called(1);
    expect(find.text(EnemyPicker.searchLabel), findsOneWidget);
  });

  testWidgets('only the visible enemies are listed (D-03)', (tester) async {
    await pumpPicker(
      tester,
      MissionEnemiesState(enemies: [_goblin, _wolf], query: 'lu'),
    );

    expect(find.byKey(EnemyPicker.enemyKeyFor('enemy-wolf')), findsOneWidget);
    expect(find.byKey(EnemyPicker.enemyKeyFor('enemy-goblin')), findsNothing);
  });

  testWidgets('«Mostra tutti» refetches the whole bestiary (D-03)', (
    tester,
  ) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_wolf]));

    await tester.tap(find.byKey(EnemyPicker.showAllKey));
    await tester.pump();

    verify(() => enemiesCubit.setShowAll(true)).called(1);
    expect(find.text(EnemyPicker.showAllLabel), findsOneWidget);
  });

  testWidgets('a legendary enemy shows «Leggendario» (D-19)', (tester) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_wolf, _dragon]));

    expect(
      find.descendant(
        of: find.byKey(EnemyPicker.enemyKeyFor('enemy-dragon')),
        matching: find.text(EnemyPicker.legendaryLabel),
      ),
      findsOneWidget,
    );
    expect(find.text(EnemyPicker.legendaryLabel), findsOneWidget);
  });

  testWidgets('tapping a row picks the enemy (D-02)', (tester) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_wolf, _goblin]));

    await tester.tap(find.byKey(EnemyPicker.enemyKeyFor('enemy-goblin')));

    expect(picks, [_goblin]);
  });

  testWidgets('the list is built lazily (ui-ux)', (tester) async {
    await pumpPicker(tester, MissionEnemiesState(enemies: [_wolf]));

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
  });
}
