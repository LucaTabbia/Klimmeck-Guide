import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_fixtures.dart';
import '../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
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
  late MockTravelRepository travelRepository;
  late MockInAppNotificationsCubit notices;
  late StreamController<QuestAcceptanceState> acceptanceStates;
  late int accepted;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.enemySheet1,
      CloudinaryAssets.enemySheet2,
      CloudinaryAssets.enemyTornSheet1,
      CloudinaryAssets.enemyTornSheet2,
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
    travelRepository = MockTravelRepository();
    when(
      () => travelRepository.previewQuest(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).thenAnswer((_) async => null);
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
    Stream<CharacterState> characterStates = const Stream.empty(),
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
      characterStates,
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
            RepositoryProvider<TravelRepository>.value(value: travelRepository),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptance),
            BlocProvider<InAppNotificationsCubit>.value(value: notices),
            BlocProvider<PrisonCubit>(
              create: (_) => PrisonCubit(
                clock: FakeServerClockService(DateTime.utc(2026, 11, 10)),
              ),
            ),
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
    testWidgets('the open sheet scroll view does not clip the torn piece', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');

      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('board-sheet-h-1')),
      );
      expect(scroll.clipBehavior, Clip.none);
    });

    testWidgets('a completed tear slides the body off the screen', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');

      await dragSheetLeft(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.getRect(find.byKey(TearablePaper.bodyKey)).right,
        lessThan(0),
      );
    });

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
    testWidgets('tearing a quest that travels goes to the map as soon as the '
        'sheet has left, before the server answers', (tester) async {
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');

      await dragSheetLeft(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(accepted, 1);

      acceptanceStates.add(const QuestAccepted('h-1'));
      await tester.pump();
      expect(accepted, 1);
    });

    testWidgets('tearing a story stays on the board', (tester) async {
      await pumpBoard(
        tester,
        quests: [
          buildQuest(id: 's-paladin', type: 'story', minTitle: 'paladin'),
        ],
        character: characterWithLanesJson(title: 'paladin'),
      );
      await openSheet(tester, 's-paladin');

      await dragSheetLeft(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(accepted, 0);
    });

    testWidgets('a story or worldMission acceptance stays on the board', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [
          buildQuest(id: 's-1', type: 'story'),
          buildQuest(id: 'w-1', type: 'worldMission'),
        ],
      );

      acceptanceStates.add(const QuestAccepted('s-1'));
      await tester.pump();
      acceptanceStates.add(const QuestAccepted('w-1'));
      await tester.pump();

      expect(accepted, 0);
    });

    testWidgets('a story acceptance closes the sheet and stays on the board', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [
          buildQuest(id: 's-paladin', type: 'story', minTitle: 'paladin'),
        ],
        character: characterWithLanesJson(title: 'paladin'),
      );
      await openSheet(tester, 's-paladin');
      expect(find.byType(TearablePaper), findsOneWidget);

      acceptanceStates.add(const QuestAccepted('s-paladin'));
      await tester.pumpAndSettle();

      expect(find.byType(TearablePaper), findsNothing);
      expect(accepted, 0);
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

      // il rifiuto arriva prima che il foglio sia uscito: si resta sul Tabellone
      expect(accepted, 0);
      expect(paperState.isTorn, isFalse);
      verifyNever(
        () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
      );
      verifyNever(() => acceptance.reset());
      verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
    });
  });

  group('travel preview (FOOD-02)', () {
    void stubTravelPreview(TravelPreview? preview) => when(
      () => travelRepository.previewQuest(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).thenAnswer((_) async => preview);

    void verifyNoTravelPreview() => verifyNever(
      () => travelRepository.previewQuest(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    );

    Text travelLine(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(QuestInfoSheet.travelLineKey));

    testWidgets(
      'opening an acceptable standard quest asks its travel preview once '
      '(D-04, D-08)',
      (tester) async {
        await pumpBoard(
          tester,
          quests: [buildQuest(id: 'h-1', type: 'hunt')],
        );
        await openSheet(tester, 'h-1');

        verify(
          () =>
              travelRepository.previewQuest(characterId: 'c-1', questId: 'h-1'),
        ).called(1);
      },
    );

    testWidgets('an acceptable story asks no travel preview (D-04)', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: [
          buildQuest(
            id: 's-paladin',
            type: 'story',
            minTitle: 'paladin',
            requiredPoints: 100,
          ),
        ],
      );
      await openSheet(tester, 's-paladin');

      expect(find.byType(TearablePaper), findsOneWidget);
      verifyNoTravelPreview();
    });

    testWidgets(
      'a quest the viewer cannot accept asks no travel preview (D-04)',
      (tester) async {
        await pumpBoard(
          tester,
          quests: [buildQuest(id: 'h-2', type: 'hunt')],
          character: characterWithLanesJson(
            title: 'paladin',
            pendingQuest: laneJson(id: 'pq-x', questId: 'h-other'),
          ),
        );
        await openSheet(tester, 'h-2');

        expect(find.byType(TearablePaper), findsOneWidget);
        verifyNoTravelPreview();
      },
    );

    group('a sheet opened before the quest is acceptable', () {
      late StreamController<CharacterState> characterStates;

      setUp(() {
        characterStates = StreamController<CharacterState>.broadcast();
        addTearDown(characterStates.close);
      });

      CharacterLoaded characterWith({Map<String, dynamic>? pendingQuest}) =>
          CharacterLoaded(
            Character.fromJson(
              characterWithLanesJson(
                title: 'paladin',
                locationId: 'city-marker-1',
                pendingQuest: pendingQuest,
              ),
            ),
          );

      Future<void> openBusySheet(WidgetTester tester) async {
        await pumpBoard(
          tester,
          quests: [buildQuest(id: 'h-2', type: 'hunt')],
          character: characterWithLanesJson(
            title: 'paladin',
            locationId: 'city-marker-1',
            pendingQuest: laneJson(id: 'pq-x', questId: 'h-other'),
          ),
          characterStates: characterStates.stream,
        );
        await openSheet(tester, 'h-2');
      }

      Future<void> emitCharacter(
        WidgetTester tester,
        CharacterLoaded state,
      ) async {
        characterStates.add(state);
        await tester.pumpAndSettle();
      }

      testWidgets(
        'asks the travel preview once the quest becomes acceptable (D-04)',
        (tester) async {
          stubTravelPreview(
            TravelPreview.fromJson(
              travelPreviewJson(food: [travelFoodItemJson()], hpLost: 0),
            ),
          );
          await openBusySheet(tester);
          verifyNoTravelPreview();

          await emitCharacter(tester, characterWith());

          verify(
            () => travelRepository.previewQuest(
              characterId: 'c-1',
              questId: 'h-2',
            ),
          ).called(1);
          expect(
            travelLine(tester).data,
            'Viaggio: 1x Razione da viaggio · nessuna perdita',
          );
        },
      );

      testWidgets(
        'a loaded preview is not asked again when the viewer changes (D-04)',
        (tester) async {
          await openBusySheet(tester);

          await emitCharacter(tester, characterWith());
          await emitCharacter(
            tester,
            characterWith(
              pendingQuest: laneJson(id: 'pq-x', questId: 'h-other'),
            ),
          );
          await emitCharacter(tester, characterWith());

          verify(
            () => travelRepository.previewQuest(
              characterId: 'c-1',
              questId: 'h-2',
            ),
          ).called(1);
        },
      );
    });

    testWidgets('the travel line appears once the preview answers (D-04)', (
      tester,
    ) async {
      stubTravelPreview(
        TravelPreview.fromJson(
          travelPreviewJson(food: [travelFoodItemJson()], hpLost: 0),
        ),
      );
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');
      await tester.pump();

      expect(find.byKey(QuestInfoSheet.travelLineKey), findsOneWidget);
      expect(
        travelLine(tester).data,
        'Viaggio: 1x Razione da viaggio · nessuna perdita',
      );
    });

    testWidgets(
      'a starving preview makes the paper resist and sends nothing (D-04)',
      (tester) async {
        final haptics = recordHaptics(tester);
        stubTravelPreview(
          TravelPreview.fromJson(
            travelPreviewJson(
              food: const [],
              hpLost: 20910,
              arrivesAlive: false,
            ),
          ),
        );
        await pumpBoard(
          tester,
          quests: [buildQuest(id: 'h-1', type: 'hunt')],
        );
        await openSheet(tester, 'h-1');
        await tester.pump();

        expect(
          travelLine(tester).data,
          'Viaggio: Non hai cibo a sufficienza per il viaggio',
        );
        expect(travelLine(tester).style?.color, KlimmeckGuideTheme.bloodRed);

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
      },
    );

    testWidgets('a failed preview shows no line and keeps the swipe (D-04)', (
      tester,
    ) async {
      when(
        () => travelRepository.previewQuest(
          characterId: any(named: 'characterId'),
          questId: any(named: 'questId'),
        ),
      ).thenThrow(const TravelException(TravelFailure.forbidden));
      await pumpBoard(
        tester,
        quests: [buildQuest(id: 'h-1', type: 'hunt')],
      );
      await openSheet(tester, 'h-1');
      await tester.pump();

      expect(find.byKey(QuestInfoSheet.travelLineKey), findsNothing);

      await dragSheetLeft(tester);

      verify(
        () => acceptance.accept(characterId: 'c-1', questId: 'h-1'),
      ).called(1);
      verifyNever(
        () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
      );
    });

    testWidgets(
      'a starving acceptance refusal recomposes the paper and refreshes the '
      'preview (D-05)',
      (tester) async {
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
          const QuestAcceptanceFailed('h-1', QuestAcceptanceFailure.starving),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(paperState.isTorn, isFalse);
        verify(
          () =>
              travelRepository.previewQuest(characterId: 'c-1', questId: 'h-1'),
        ).called(2);
        verify(() => questCubit.refreshQuests(cityId: 'city-1')).called(1);
      },
    );

    testWidgets(
      'another refusal recomposes without refreshing the preview (D-05)',
      (tester) async {
        await pumpBoard(
          tester,
          quests: [buildQuest(id: 'h-1', type: 'hunt')],
        );
        await openSheet(tester, 'h-1');
        await dragSheetLeft(tester);
        final paperState = tester.state<TearablePaperState>(
          find.byType(TearablePaper),
        );

        acceptanceStates.add(
          const QuestAcceptanceFailed('h-1', QuestAcceptanceFailure.full),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(paperState.isTorn, isFalse);
        verify(
          () =>
              travelRepository.previewQuest(characterId: 'c-1', questId: 'h-1'),
        ).called(1);
      },
    );
  });
}
