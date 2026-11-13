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
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';
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
  List<Map<String, dynamic>>? slots,
  Map<String, dynamic>? prizes,
  bool? noEffect,
  bool? awaitingRescue,
}) => buildQuest(
  id: id,
  type: type,
  markerId: markerId,
  minTitle: minTitle,
  registered: registered,
  slots: slots,
  prizes: prizes,
  noEffect: noEffect,
  awaitingRescue: awaitingRescue,
);

Map<String, dynamic> _injuredCharacterJson(List<String> injuries) {
  final json = characterWithLanesJson(
    title: 'paladin',
    locationId: 'city-marker-1',
  );
  return {
    ...json,
    'status': {...json['status'] as Map<String, dynamic>, 'injuries': injuries},
  };
}

void main() {
  late MockQuestCubit questCubit;
  late MockCharacterCubit characterCubit;
  late MockAuthCubit authCubit;
  late MockQuestAcceptanceCubit acceptanceCubit;
  late MockTravelRepository travelRepository;
  late MockPrisonCubit prisonCubit;
  late StreamController<QuestState> questStates;
  late StreamController<PrisonState> prisonStates;

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
      CloudinaryAssets.magicSheet,
      CloudinaryAssets.magicTornSheet,
    ]);
    questCubit = MockQuestCubit();
    characterCubit = MockCharacterCubit();
    authCubit = MockAuthCubit();
    acceptanceCubit = MockQuestAcceptanceCubit();
    travelRepository = MockTravelRepository();
    prisonCubit = MockPrisonCubit();
    prisonStates = StreamController<PrisonState>.broadcast();
    addTearDown(prisonStates.close);
    when(
      () => travelRepository.previewQuest(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ).thenAnswer((_) async => null);
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
    Stream<CharacterState>? characterStates,
    PrisonState prison = const PrisonState(null),
  }) async {
    useLandscapePhone(tester);
    whenListen(prisonCubit, prisonStates.stream, initialState: prison);
    whenListen(
      characterCubit,
      characterStates ?? const Stream<CharacterState>.empty(),
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
            RepositoryProvider<TravelRepository>.value(value: travelRepository),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<QuestAcceptanceCubit>.value(value: acceptanceCubit),
            BlocProvider<PrisonCubit>.value(value: prisonCubit),
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

  testWidgets('an enemy is whole for a higher rank on both wire shapes, torn '
      'above the rank and torn once taken (quick 261111-enm)', (tester) async {
    const rookieSeat = [
      {'title': 'rookie', 'count': 1},
    ];
    await pumpBoard(
      tester,
      quests: loaded([
        _boardQuest('e-free', 'enemy'),
        _boardQuest('e-exact', 'enemy', slots: rookieSeat),
        _boardQuest('e-hero', 'enemy', minTitle: 'hero'),
        _boardQuest(
          'e-taken',
          'enemy',
          slots: rookieSeat,
          registered: [
            {'character': 'c-9', 'title': 'legend'},
          ],
        ),
      ]),
    );

    expect(isTorn(tester, 'e-free'), isFalse);
    expect(isTorn(tester, 'e-exact'), isFalse);
    expect(isTorn(tester, 'e-hero'), isTrue);
    expect(isTorn(tester, 'e-taken'), isTrue);
  });

  testWidgets('a boss with a seat of another rank stays torn '
      '(quick 261111-enm)', (tester) async {
    await pumpBoard(
      tester,
      quests: loaded([
        _boardQuest(
          'b-rookie',
          'boss',
          slots: [
            {'title': 'rookie', 'count': 2},
          ],
        ),
        _boardQuest(
          'b-paladin',
          'boss',
          slots: [
            {'title': 'paladin', 'count': 2},
          ],
        ),
      ]),
    );

    expect(isTorn(tester, 'b-rookie'), isTrue);
    expect(isTorn(tester, 'b-paladin'), isFalse);
  });

  testWidgets(
    'a magic quest above the title is torn until the rank (quick 261110-mag)',
    (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([_boardQuest('m-1', 'magic', minTitle: 'mage')]),
      );

      expect(isTorn(tester, 'm-1'), isTrue);
    },
  );

  testWidgets(
    'a busy standard lane leaves the sheets whole (quick 261110-mag)',
    (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([
          _boardQuest('h-1', 'hunt'),
          _boardQuest('m-1', 'magic', minTitle: 'mage'),
          _boardQuest('m-2', 'magic', minTitle: 'paladin'),
        ]),
        character: characterWithLanesJson(
          title: 'paladin',
          pendingQuest: laneJson(id: 'pq-1', questId: 'other'),
        ),
      );

      expect(isTorn(tester, 'h-1'), isFalse);
      expect(isTorn(tester, 'm-2'), isFalse);
      expect(isTorn(tester, 'm-1'), isTrue);
    },
  );

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

  group('cure rows (BE Phase 18)', () {
    final heal = _boardQuest('he-1', 'heal', prizes: {'cure': questCureJson()});

    Future<void> openHeal(WidgetTester tester) async {
      await tester.ensureVisible(paper('he-1'));
      await tester.tap(paper('he-1'));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets(
      "the Board sheet lists the character's curable injuries (D-19)",
      (tester) async {
        await pumpBoard(
          tester,
          quests: loaded([heal]),
          character: _injuredCharacterJson(['contusion', 'blindness']),
        );

        await openHeal(tester);

        expect(find.text('Cura le tue ferite: contusione'), findsOneWidget);
        expect(find.text('Vita: almeno il 50%'), findsOneWidget);
      },
    );

    testWidgets(
      'a new character from the stream updates the cure line (D-19)',
      (tester) async {
        final characterStates = StreamController<CharacterState>.broadcast();
        addTearDown(characterStates.close);
        await pumpBoard(
          tester,
          quests: loaded([heal]),
          character: _injuredCharacterJson(['contusion']),
          characterStates: characterStates.stream,
        );
        await openHeal(tester);
        expect(find.text('Cura le tue ferite: contusione'), findsOneWidget);

        characterStates.add(
          CharacterLoaded(Character.fromJson(_injuredCharacterJson([]))),
        );
        await tester.pump();

        expect(find.byKey(QuestInfoSheet.cureLineKey), findsNothing);
        expect(find.text('Vita: almeno il 50%'), findsOneWidget);
      },
    );
  });

  group('prison (quick 261110-cgd)', () {
    const imprisoned = PrisonState(Duration(hours: 9, minutes: 12));

    Future<void> open(WidgetTester tester, String id) async {
      await tester.ensureVisible(paper(id));
      await tester.tap(paper(id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('in prison every sheet is torn and none can be torn off '
        '(quick 261110-cgd)', (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([_boardQuest('h-1', 'hunt')]),
        prison: imprisoned,
      );

      expect(isTorn(tester, 'h-1'), isTrue);

      await open(tester, 'h-1');
      expect(
        tester.widget<TearablePaper>(find.byType(TearablePaper)).canTear,
        isFalse,
      );
    });

    testWidgets('the open sheet says «Sei in prigione» with the release time '
        '(quick 261110-cgd)', (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([_boardQuest('h-1', 'hunt')]),
        prison: imprisoned,
      );
      await open(tester, 'h-1');

      expect(
        tester.widget<Text>(find.byKey(QuestInfoSheet.blockedReasonKey)).data,
        'Sei in prigione: uscirai fra 9 h 12 min',
      );
    });

    testWidgets('at the release the sheets turn whole again '
        '(quick 261110-cgd)', (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([_boardQuest('h-1', 'hunt')]),
        prison: imprisoned,
      );
      expect(isTorn(tester, 'h-1'), isTrue);

      prisonStates.add(const PrisonState(null));
      await tester.pump();
      await tester.pump();

      expect(isTorn(tester, 'h-1'), isFalse);
    });
  });

  group('heal with no effect (D-20)', () {
    final inert = _boardQuest('heal-1', 'heal', noEffect: true);

    Future<void> openInert(WidgetTester tester) async {
      await tester.ensureVisible(paper('heal-1'));
      await tester.tap(paper('heal-1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    TearablePaper openSheet(WidgetTester tester) =>
        tester.widget<TearablePaper>(find.byType(TearablePaper));

    testWidgets('a heal with no effect stays in its place, drawn torn (D-20)', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        quests: loaded([inert, _boardQuest('h-1', 'hunt')]),
      );

      expect(paper('heal-1'), findsOneWidget);
      expect(isTorn(tester, 'heal-1'), isTrue);
      expect(isTorn(tester, 'h-1'), isFalse);
    });

    testWidgets(
      'its open sheet ignores the swipe and never calls accept (D-20)',
      (tester) async {
        await pumpBoard(tester, quests: loaded([inert]));
        await openInert(tester);

        final visibleCenter = Offset(
          tester.getCenter(find.byType(TearablePaper)).dx,
          180,
        );
        await tester.dragFrom(visibleCenter, const Offset(-600, 0));
        await tester.pump(const Duration(seconds: 1));

        expect(openSheet(tester).isEnabled, isFalse);
        verifyNever(
          () => acceptanceCubit.accept(
            characterId: any(named: 'characterId'),
            questId: any(named: 'questId'),
          ),
        );
      },
    );

    testWidgets('its open sheet says why in the world (D-20)', (tester) async {
      await pumpBoard(tester, quests: loaded([inert]));
      await openInert(tester);

      expect(
        tester.widget<Text>(find.byKey(QuestInfoSheet.blockedReasonKey)).data,
        'Il tempio non può fare nulla per te adesso',
      );
    });

    testWidgets(
      'when the reread list clears the flag the sheet is whole and tearable again (D-20)',
      (tester) async {
        await pumpBoard(tester, quests: loaded([inert]));
        await openInert(tester);
        expect(openSheet(tester).isEnabled, isFalse);

        questStates.add(loaded([_boardQuest('heal-1', 'heal')]));
        await tester.pump();
        await tester.pump();

        expect(isTorn(tester, 'heal-1'), isFalse);
        expect(openSheet(tester).isEnabled, isTrue);
      },
    );
  });

  group('quest awaiting its rescue (quick 261113-aql)', () {
    final locked = _boardQuest('d-1', 'dungeon', awaitingRescue: true);

    Future<void> openLocked(WidgetTester tester) async {
      await tester.ensureVisible(paper('d-1'));
      await tester.tap(paper('d-1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    TearablePaper openSheet(WidgetTester tester) =>
        tester.widget<TearablePaper>(find.byType(TearablePaper));

    testWidgets('a dungeon awaiting its rescue is drawn torn, an unlocked one '
        'stays whole (quick 261113-aql)', (tester) async {
      await pumpBoard(
        tester,
        quests: loaded([
          locked,
          _boardQuest('d-2', 'dungeon', awaitingRescue: false),
          _boardQuest('h-1', 'hunt', awaitingRescue: true),
        ]),
      );

      expect(isTorn(tester, 'd-1'), isTrue);
      expect(isTorn(tester, 'h-1'), isTrue);
      expect(isTorn(tester, 'd-2'), isFalse);
    });

    testWidgets('its open sheet says why and has no accept action '
        '(quick 261113-aql)', (tester) async {
      await pumpBoard(tester, quests: loaded([locked]));
      await openLocked(tester);

      expect(
        tester.widget<Text>(find.byKey(QuestInfoSheet.blockedReasonKey)).data,
        'Soccorso in corso: la missione riapre quando il soccorso si conclude.',
      );

      final visibleCenter = Offset(
        tester.getCenter(find.byType(TearablePaper)).dx,
        180,
      );
      await tester.dragFrom(visibleCenter, const Offset(-600, 0));
      await tester.pump(const Duration(seconds: 1));

      expect(openSheet(tester).canTear, isFalse);
      expect(openSheet(tester).isEnabled, isFalse);
      verifyNever(
        () => acceptanceCubit.accept(
          characterId: any(named: 'characterId'),
          questId: any(named: 'questId'),
        ),
      );
    });

    testWidgets('when a reread list brings the lock the open sheet tears and '
        'says why (WR-01, quick 261113-aql)', (tester) async {
      await pumpBoard(tester, quests: loaded([_boardQuest('d-1', 'dungeon')]));
      await openLocked(tester);
      expect(openSheet(tester).isEnabled, isTrue);

      questStates.add(loaded([locked]));
      await tester.pump();
      await tester.pump();

      expect(isTorn(tester, 'd-1'), isTrue);
      expect(openSheet(tester).isEnabled, isFalse);
      expect(openSheet(tester).canTear, isFalse);
      expect(find.byKey(QuestInfoSheet.blockedReasonKey), findsOneWidget);
    });

    testWidgets('when a reread list drops the lock the sheet is whole and '
        'tearable again (WR-01, quick 261113-aql)', (tester) async {
      await pumpBoard(tester, quests: loaded([locked]));
      await openLocked(tester);
      expect(openSheet(tester).isEnabled, isFalse);

      questStates.add(loaded([_boardQuest('d-1', 'dungeon')]));
      await tester.pump();
      await tester.pump();

      expect(isTorn(tester, 'd-1'), isFalse);
      expect(openSheet(tester).isEnabled, isTrue);
      expect(find.byKey(QuestInfoSheet.blockedReasonKey), findsNothing);
    });
  });
}
