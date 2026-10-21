import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/quest_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late MockMainScreenCubit mainScreenCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    mainScreenCubit = MockMainScreenCubit();
    whenListen(
      characterCubit,
      Stream<CharacterState>.empty(),
      initialState: CharacterInitial(),
    );
    whenListen(
      questCubit,
      Stream<QuestState>.empty(),
      initialState: QuestInitial(),
    );
    whenListen(
      mainScreenCubit,
      Stream<MainScreenState>.empty(),
      initialState: MainScreenInitial(),
    );
    when(() => characterCubit.loadCharacter(any())).thenAnswer((_) async {});
    when(() => questCubit.loadQuest()).thenAnswer((_) async {});
  });

  testWidgets('loads exactly the character of the session', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
          ],
          child: const MainScreen(characterId: 'c-42'),
        ),
      ),
    );
    await tester.pump();

    verify(() => characterCubit.loadCharacter('c-42')).called(1);
    verify(() => questCubit.loadQuest()).called(1);
  });

  group('satchel wiring', () {
    final cities = [
      City.fromJson({
        'id': 'city-1',
        'markerLocation': {
          'id': 'city-marker-1',
          'location': [1.0, 2.0],
        },
      }),
    ];

    late MockQuestAcceptanceCubit acceptanceCubit;
    late MockInAppNotificationsCubit noticesCubit;
    late StreamController<QuestAcceptanceState> acceptanceStates;

    setUp(() {
      registerFallbackValue(const KGNotification(title: '', description: ''));
      acceptanceCubit = MockQuestAcceptanceCubit();
      noticesCubit = MockInAppNotificationsCubit();
      acceptanceStates = StreamController<QuestAcceptanceState>.broadcast();
      addTearDown(acceptanceStates.close);
      whenListen(
        acceptanceCubit,
        acceptanceStates.stream,
        initialState: const QuestAcceptanceIdle(),
      );
      final svg =
          File('${Directory.systemTemp.createTempSync('kg_svg').path}/i.svg')
            ..writeAsStringSync(
              '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
            );
      for (final entry in SatchelLayout.entries) {
        SvgCache().add(CloudinaryAssets.url(entry.assetPath), svg);
      }
      SvgCache().add(CloudinaryAssets.url(CloudinaryAssets.pouch), svg);
      whenListen(
        mainScreenCubit,
        Stream<MainScreenState>.empty(),
        initialState: MainScreenLoadData(cities),
      );
    });

    Future<PageController> pumpOpenSatchel(
      WidgetTester tester,
      String locationId,
    ) async {
      useLandscapePhone(tester);
      final authStates = StreamController<AuthState>.broadcast();
      final intentCubit = NotificationIntentCubit(authStates.stream);
      addTearDown(() async {
        await intentCubit.close();
        await authStates.close();
      });
      whenListen(
        characterCubit,
        Stream<CharacterState>.empty(),
        initialState: CharacterLoaded(
          Character.fromJson(characterWithLanesJson(locationId: locationId)),
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<QuestCubit>.value(value: questCubit),
              BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
              BlocProvider<NotificationIntentCubit>.value(value: intentCubit),
              BlocProvider<QuestAcceptanceCubit>.value(value: acceptanceCubit),
              BlocProvider<InAppNotificationsCubit>.value(value: noticesCubit),
            ],
            child: MainScreen(
              characterId: 'c-1',
              pagesBuilder: (_) => [
                for (final e in SatchelLayout.entries)
                  SizedBox.expand(key: ValueKey('page-${e.pageIndex}')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(CachedSvg).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      return tester.widget<PageView>(find.byType(PageView)).controller!;
    }

    Future<void> tapItem(WidgetTester tester, int pageIndex) async {
      await tester.tapAt(
        SatchelLayout.centerOf(
          SatchelLayout.entries[pageIndex],
          const Size(780, 360),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('off a city marker the Bacheca item does nothing', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'poi-9');

      await tapItem(tester, SatchelLayout.boardPageIndex);

      expect(controller.page!.round(), 0);
    });

    testWidgets('off a city marker another item still navigates', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'poi-9');

      await tapItem(tester, 5);

      expect(controller.page!.round(), 5);
    });

    testWidgets('on a city marker the Bacheca item opens the board', (
      tester,
    ) async {
      final controller = await pumpOpenSatchel(tester, 'city-marker-1');

      await tapItem(tester, SatchelLayout.boardPageIndex);

      expect(controller.page!.round(), 4);
    });

    testWidgets(
      'a rejection answered away from the Board still shows the banner',
      (tester) async {
        final controller = await pumpOpenSatchel(tester, 'city-marker-1');
        await tapItem(tester, 5);
        expect(controller.page!.round(), 5);

        acceptanceStates.add(
          const QuestAcceptanceFailed(
            'q-1',
            QuestAcceptanceFailure.notAcceptable,
          ),
        );
        await tester.pump();

        verify(
          () => noticesCubit.publishNotice(
            const KGNotification(
              title: 'Missione non accettata',
              description: 'Missione non disponibile, avvisa il locandiere',
            ),
            dedupKey: 'quest-acceptance|notAcceptable|q-1',
          ),
        ).called(1);
        verify(() => acceptanceCubit.reset()).called(1);
      },
    );
  });
}
