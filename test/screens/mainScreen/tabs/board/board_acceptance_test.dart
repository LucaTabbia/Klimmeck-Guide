import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_fixtures.dart';
import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/haptic_recorder.dart';
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

void main() {
  late MockQuestCubit questCubit;
  late MockCharacterCubit characterCubit;
  late MockAuthCubit authCubit;
  late MockQuestAcceptanceCubit acceptance;
  late MockInAppNotificationsCubit notices;
  late StreamController<QuestAcceptanceState> acceptanceStates;
  late int accepted;

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
    acceptance = MockQuestAcceptanceCubit();
    notices = MockInAppNotificationsCubit();
    accepted = 0;
    acceptanceStates = StreamController<QuestAcceptanceState>.broadcast();
    addTearDown(acceptanceStates.close);
    when(
      () => questCubit.refreshQuests(cityId: any(named: 'cityId')),
    ).thenAnswer((_) async {});
    when(
      () => acceptance.accept(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).thenAnswer((_) async {});
    whenListen(
      acceptance,
      acceptanceStates.stream,
      initialState: const QuestAcceptanceIdle(),
    );
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
    required List<Quest> quests,
    Map<String, dynamic>? character,
    QuestAcceptanceState initialAcceptance = const QuestAcceptanceIdle(),
  }) async {
    useLandscapePhone(tester);
    whenListen(
      acceptance,
      acceptanceStates.stream,
      initialState: initialAcceptance,
    );
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
    whenListen(
      questCubit,
      const Stream<QuestState>.empty(),
      initialState: QuestLoaded(
        quests,
        cityId: 'city-1',
        cityPointIds: const {'poi-1'},
      ),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptance),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
          ],
          child: Scaffold(
            body: Board(cities: _cities, onQuestAccepted: () => accepted++),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openSheet(WidgetTester tester, String id) async {
    final paper = find.byKey(ValueKey(id));
    await tester.ensureVisible(paper);
    await tester.tap(paper);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> dragSheetLeft(WidgetTester tester) async {
    final visibleCenter = Offset(
      tester.getCenter(find.byType(TearablePaper)).dx,
      180,
    );
    await tester.dragFrom(visibleCenter, const Offset(-600, 0));
    await tester.pump(const Duration(seconds: 1));
  }

  group('swipe to accept', () {
    testWidgets('tearing the open sheet accepts with the session character', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');

      await dragSheetLeft(tester);

      verify(
        () => acceptance.accept(characterId: 'c-1', questId: 'h-1'),
      ).called(1);
      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('the board papers carry no tear gesture', (tester) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );

      await tester.ensureVisible(find.byType(Sheet));
      await tester.drag(find.byType(Sheet), const Offset(-600, 0));
      await tester.pump(const Duration(seconds: 1));

      verifyNever(
        () => acceptance.accept(
          characterId: any(named: 'characterId'),
          questId: any(named: 'questId'),
        ),
      );
      expect(find.byType(TearablePaper), findsNothing);
    });

    testWidgets('a lane-busy quest resists and sends nothing', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-2', type: 'hunt')],
        character: characterWithLanesJson(
          title: 'paladin',
          pendingQuest: laneJson(id: 'pq-x', questId: 'h-other'),
        ),
      );
      await openSheet(tester, 'h-2');

      await dragSheetLeft(tester);

      verifyNever(
        () => acceptance.accept(
          characterId: any(named: 'characterId'),
          questId: any(named: 'questId'),
        ),
      );
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      expect(
        tester.state<TearablePaperState>(find.byType(TearablePaper)).isTorn,
        isFalse,
      );
    });

    testWidgets('the own torn story cannot be torn again', (tester) async {
      await pumpBoard(
        tester,
        quests: [
          buildQuest(id: 's-paladin', type: 'story', minTitle: 'paladin'),
        ],
        character: characterWithLanesJson(
          title: 'paladin',
          activeStoryQuest: laneJson(id: 'pq-s', questId: 's-paladin'),
        ),
      );
      await openSheet(tester, 's-paladin');

      await dragSheetLeft(tester);

      verifyNever(
        () => acceptance.accept(
          characterId: any(named: 'characterId'),
          questId: any(named: 'questId'),
        ),
      );
    });

    testWidgets('QuestAccepting disables the paper', (tester) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
        initialAcceptance: const QuestAccepting('h-1'),
      );
      await openSheet(tester, 'h-1');

      final paper = tester.widget<TearablePaper>(find.byType(TearablePaper));
      expect(paper.isEnabled, isFalse);
    });

    testWidgets('exactly one tearable paper while a sheet is open', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      expect(find.byType(TearablePaper), findsNothing);

      await openSheet(tester, 'h-1');

      expect(find.byType(TearablePaper), findsOneWidget);
    });
  });

  group('acceptance outcomes', () {
    testWidgets('only QuestAccepted goes to the map', (tester) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );

      acceptanceStates.add(const QuestAccepting('h-1'));
      await tester.pump();
      expect(accepted, 0);

      acceptanceStates.add(const QuestAccepted('h-1'));
      await tester.pump();
      expect(accepted, 1);
    });

    testWidgets('a rejection recomposes the paper and leaves the rest alone', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');
      await dragSheetLeft(tester);
      final paperState = tester.state<TearablePaperState>(
        find.byType(TearablePaper),
      );
      expect(paperState.isTorn, isTrue);

      acceptanceStates.add(
        const QuestAcceptanceFailed('h-1', QuestAcceptanceFailure.full),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(accepted, 0);
      expect(paperState.isTorn, isFalse);
      verifyNever(
        () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
      );
      verifyNever(() => acceptance.reset());
      verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
    });
  });
}
