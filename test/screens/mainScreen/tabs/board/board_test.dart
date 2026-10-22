import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_fixtures.dart';
import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

final _cities = [
  City.fromJson({
    'id': 'city-1',
    'markerLocation': {
      'id': 'city-marker-1',
      'location': [1.0, 2.0],
    },
  }),
];

Quest _boardQuest(
  String id,
  String type, {
  String markerId = 'poi-1',
  String? minTitle = 'rookie',
  List<Object> registered = const [],
}) => buildQuest(
  id: id,
  type: type,
  markerId: markerId,
  minTitle: minTitle,
  registered: registered,
);

void main() {
  late MockQuestCubit questCubit;
  late MockCharacterCubit characterCubit;
  late MockAuthCubit authCubit;
  late MockQuestAcceptanceCubit acceptanceCubit;
  late StreamController<QuestState> questStates;

  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.huntSheet1,
      CloudinaryAssets.huntSheet2,
      CloudinaryAssets.huntTornSheet1,
      CloudinaryAssets.huntTornSheet2,
      CloudinaryAssets.storySheet1,
      CloudinaryAssets.storySheet2,
      CloudinaryAssets.storyTornSheet1,
      CloudinaryAssets.storyTornSheet2,
      CloudinaryAssets.questSheet1,
      CloudinaryAssets.questSheet2,
    ]);
    questCubit = MockQuestCubit();
    characterCubit = MockCharacterCubit();
    authCubit = MockAuthCubit();
    acceptanceCubit = MockQuestAcceptanceCubit();
    whenListen(
      acceptanceCubit,
      const Stream<QuestAcceptanceState>.empty(),
      initialState: const QuestAcceptanceIdle(),
    );
    questStates = StreamController<QuestState>.broadcast();
    addTearDown(questStates.close);
    when(
      () => questCubit.refreshQuests(cityId: any(named: 'cityId')),
    ).thenAnswer((_) async {});
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser().copyWith(twitchPoints: 1200),
        accessToken: testAccessToken,
      ),
    );
  });

  Future<void> pumpBoard(
    WidgetTester tester, {
    required QuestLoaded quests,
    Map<String, dynamic>? character,
  }) async {
    useLandscapePhone(tester);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        Character.fromJson(
          character ??
              characterWithLanesJson(
                title: 'paladin',
                locationId: 'city-marker-1',
              ),
        ),
      ),
    );
    whenListen(questCubit, questStates.stream, initialState: quests);
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptanceCubit),
          ],
          child: Scaffold(body: Board(cities: _cities)),
        ),
      ),
    );
    await tester.pump();
  }

  QuestLoaded loaded(
    List<Quest> quests, {
    String cityId = 'city-1',
    Set<String> pointIds = const {'poi-1'},
  }) => QuestLoaded(quests, cityId: cityId, cityPointIds: pointIds);

  Finder paper(String id) => find.byKey(ValueKey(id));

  bool isTorn(WidgetTester tester, String id) =>
      tester.widget<Sheet>(paper(id)).isTorn;

  testWidgets('opening the board refreshes the current city once', (
    tester,
  ) async {
    await pumpBoard(tester, quests: loaded([]));

    verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
  });

  testWidgets(
    'lists the city quests with its world missions and the exact title story',
    (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([
          _boardQuest('h-1', 'hunt'),
          _boardQuest('h-2', 'hunt', markerId: 'poi-9'),
          _boardQuest('wm-0', 'worldMission'),
          _boardQuest('wm-1', 'worldMission', markerId: 'poi-9'),
          _boardQuest('s-paladin', 'story', minTitle: 'paladin'),
          _boardQuest('s-mage', 'story', minTitle: 'mage'),
          _boardQuest('e-done', 'enemy'),
        ]),
        character: characterWithLanesJson(
          title: 'paladin',
          completedQuestIds: ['e-done'],
        ),
      );

      expect(paper('h-1'), findsOneWidget);
      expect(paper('wm-0'), findsOneWidget);
      expect(paper('wm-1'), findsNothing);
      expect(paper('s-paladin'), findsOneWidget);
      expect(paper('h-2'), findsNothing);
      expect(paper('s-mage'), findsNothing);
      expect(paper('e-done'), findsNothing);
    },
  );

  testWidgets('tears the own active story and the full quests', (tester) async {
    await pumpBoard(
      tester,
      quests: loaded([
        _boardQuest('h-1', 'hunt'),
        _boardQuest('s-paladin', 'story', minTitle: 'paladin'),
        _boardQuest('b-full', 'boss', registered: ['c-9']),
      ]),
      character: characterWithLanesJson(
        title: 'paladin',
        activeStoryQuest: laneJson(id: 'pq-s', questId: 's-paladin'),
      ),
    );

    expect(isTorn(tester, 's-paladin'), isTrue);
    expect(isTorn(tester, 'b-full'), isTrue);
    expect(isTorn(tester, 'h-1'), isFalse);
  });

  testWidgets('never uses the POIs of another city', (tester) async {
    await pumpBoard(
      tester,
      quests: loaded([
        _boardQuest('h-1', 'hunt'),
        _boardQuest('wm-1', 'worldMission', markerId: 'poi-9'),
        _boardQuest('s-paladin', 'story', minTitle: 'paladin'),
      ], cityId: 'city-other'),
    );

    expect(paper('h-1'), findsNothing);
    expect(paper('wm-1'), findsNothing);
    expect(paper('s-paladin'), findsOneWidget);
  });

  testWidgets('off a city marker the board shows no papers and survives', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      quests: loaded([_boardQuest('h-1', 'hunt')]),
      character: characterWithLanesJson(title: 'paladin', locationId: 'poi-1'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Sheet), findsNothing);
    verify(() => questCubit.refreshQuests(cityId: null)).called(1);
  });

  testWidgets('tapping a paper opens the sheet for the live viewer', (
    tester,
  ) async {
    await pumpBoard(tester, quests: loaded([_boardQuest('h-1', 'hunt')]));

    await tester.ensureVisible(paper('h-1'));
    await tester.tap(paper('h-1'));
    await tester.pump(const Duration(milliseconds: 400));

    final sheet = tester.widget<QuestInfoSheet>(find.byType(QuestInfoSheet));
    expect(sheet.quest?.id, 'h-1');
    expect(sheet.viewer?.twitchPoints, 1200);
    expect(sheet.viewer?.title, TitleType.paladin);
  });

  testWidgets('the open sheet follows the refreshed quest by id', (
    tester,
  ) async {
    final full = _boardQuest('b-full', 'boss', registered: ['c-9']);
    await pumpBoard(tester, quests: loaded([full]));
    await tester.ensureVisible(paper('b-full'));
    await tester.tap(paper('b-full'));
    await tester.pump(const Duration(milliseconds: 400));

    final freed = _boardQuest('b-full', 'boss');
    questStates.add(loaded([freed]));
    await tester.pump();

    final sheet = tester.widget<QuestInfoSheet>(find.byType(QuestInfoSheet));
    expect(sheet.quest, freed);
    expect(isTorn(tester, 'b-full'), isFalse);
  });
}
