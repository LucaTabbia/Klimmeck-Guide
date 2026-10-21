import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest/quest_paper_asset.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late List<(Quest, String)> opened;

  setUp(() {
    opened = [];
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
  });

  Future<void> pumpLayer(
    WidgetTester tester, {
    CharacterState? character,
    QuestState? quests,
  }) async {
    useLandscapePhone(tester);
    final q = buildQuest(id: 'e-1', type: 'enemy');
    final h = buildQuest(id: 'h-1', type: 'hunt');
    seedSvgCache([
      questPaperAssetId(q, isTorn: false),
      questPaperAssetId(h, isTorn: false),
    ]);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: character,
    );
    whenListen(
      questCubit,
      const Stream<QuestState>.empty(),
      initialState: quests ?? QuestLoaded([q, h]),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
          ],
          child: Scaffold(
            body: Stack(
              children: [
                QuestPaperLayer(
                  onOpen: (quest, label) => opened.add((quest, label)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  CharacterLoaded characterWith(Map<String, dynamic> json) =>
      CharacterLoaded(Character.fromJson(json));

  testWidgets('shows the intact paper and the active label', (tester) async {
    await pumpLayer(
      tester,
      character: characterWith(
        characterWithLanesJson(
          pendingQuest: laneJson(
            questId: 'e-1',
            startDate: '2026-10-21T10:00:00.000Z',
          ),
        ),
      ),
    );

    final svg = tester.widget<CachedSvg>(
      find.descendant(
        of: find.byKey(QuestPaperLayer.paperKey),
        matching: find.byType(CachedSvg),
      ),
    );
    expect(
      svg.url,
      CloudinaryAssets.url(
        questPaperAssetId(buildQuest(id: 'e-1', type: 'enemy'), isTorn: false),
      ),
    );
    expect(find.text('In combattimento…'), findsOneWidget);
  });

  testWidgets('reads In viaggio while the start date is null', (tester) async {
    await pumpLayer(
      tester,
      character: characterWith(
        characterWithLanesJson(
          pendingQuest: laneJson(questId: 'e-1', startDate: null),
        ),
      ),
    );

    expect(find.text('In viaggio'), findsOneWidget);
  });

  testWidgets('hunt lane reads Cacciando…', (tester) async {
    await pumpLayer(
      tester,
      character: characterWith(
        characterWithLanesJson(pendingQuest: laneJson(questId: 'h-1')),
      ),
    );

    expect(find.text('Cacciando…'), findsOneWidget);
  });

  testWidgets('story and worldMission lanes never show a paper', (
    tester,
  ) async {
    await pumpLayer(
      tester,
      quests: QuestLoaded([
        buildQuest(id: 's-1', type: 'story'),
        buildQuest(id: 'w-1', type: 'worldMission'),
      ]),
      character: characterWith(
        characterWithLanesJson(
          activeStoryQuest: laneJson(questId: 's-1'),
          activeWorldMissionQuest: laneJson(id: 'pq-2', questId: 'w-1'),
        ),
      ),
    );

    expect(find.byKey(QuestPaperLayer.paperKey), findsNothing);
  });

  testWidgets('a lane quest missing from the catalogue shows nothing', (
    tester,
  ) async {
    await pumpLayer(
      tester,
      character: characterWith(
        characterWithLanesJson(pendingQuest: laneJson(questId: 'q-missing')),
      ),
    );

    expect(find.byKey(QuestPaperLayer.paperKey), findsNothing);
  });

  testWidgets('shows nothing while the catalogue is not loaded', (
    tester,
  ) async {
    await pumpLayer(
      tester,
      quests: QuestLoading(),
      character: characterWith(
        characterWithLanesJson(pendingQuest: laneJson(questId: 'e-1')),
      ),
    );

    expect(find.byKey(QuestPaperLayer.paperKey), findsNothing);
  });

  testWidgets('shows nothing while the character is not loaded', (
    tester,
  ) async {
    await pumpLayer(tester, character: CharacterLoading());

    expect(find.byKey(QuestPaperLayer.paperKey), findsNothing);
  });

  testWidgets('tapping the paper reports the quest and its label', (
    tester,
  ) async {
    await pumpLayer(
      tester,
      character: characterWith(
        characterWithLanesJson(pendingQuest: laneJson(questId: 'e-1')),
      ),
    );

    await tester.tap(find.byKey(QuestPaperLayer.paperKey));

    expect(opened, hasLength(1));
    expect(opened.single.$1.id, 'e-1');
    expect(opened.single.$2, 'In combattimento…');
  });
}
