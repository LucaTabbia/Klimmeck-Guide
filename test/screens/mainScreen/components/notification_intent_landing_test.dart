import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_popup_registry.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/test_app.dart';

void main() {
  late StreamController<AuthState> authStates;
  late NotificationIntentCubit cubit;
  late List<NotificationIntent> poppedUp;

  final questIntent = NotificationIntent(
    category: NotificationCategory.questEnd,
    id: 'q-1',
    sentAt: DateTime.utc(2026, 10, 18, 12),
  );
  final travelIntent = NotificationIntent(
    category: NotificationCategory.travelEnd,
    id: 't-1',
    sentAt: DateTime.utc(2026, 10, 18, 12),
  );

  Future<void> startSession(WidgetTester tester) async {
    authStates = StreamController<AuthState>.broadcast();
    cubit = NotificationIntentCubit(authStates.stream);
    poppedUp = [];
    addTearDown(() async {
      await cubit.close();
      await authStates.close();
    });
    authStates.add(
      AuthAuthenticated(
        user: buildTestUserWithCharacter(),
        accessToken: testAccessToken,
      ),
    );
    await tester.pump();
  }

  Future<PageController> pumpLanding(
    WidgetTester tester, {
    int initialPage = 0,
    Map<NotificationCategory, NotificationPopup>? popups,
  }) async {
    final controller = PageController(initialPage: initialPage);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<NotificationIntentCubit>.value(
          value: cubit,
          child: Scaffold(
            body: NotificationIntentLanding(
              pageController: controller,
              popups:
                  popups ??
                  {
                    NotificationCategory.questEnd: (_, intent) =>
                        poppedUp.add(intent),
                  },
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(7, (i) => Text('page $i')),
              ),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('a quest tap lands on the map tab and opens its popup', (
    tester,
  ) async {
    await startSession(tester);
    final controller = await pumpLanding(tester);
    controller.jumpToPage(3);
    await tester.pump();
    expect(find.text('page 3'), findsOneWidget);

    cubit.offer(questIntent);
    await tester.pumpAndSettle();

    expect(find.text('page 0'), findsOneWidget);
    expect(cubit.state.pending, isNull);
    expect(poppedUp, [questIntent]);
  });

  testWidgets('a type without popup still lands on the map tab', (
    tester,
  ) async {
    await startSession(tester);
    final controller = await pumpLanding(tester, popups: const {});
    controller.jumpToPage(5);
    await tester.pump();

    cubit.offer(travelIntent);
    await tester.pumpAndSettle();

    expect(find.text('page 0'), findsOneWidget);
    expect(cubit.state.pending, isNull);
    expect(poppedUp, isEmpty);
  });

  testWidgets('a root bottom sheet is closed before landing', (tester) async {
    await startSession(tester);
    await pumpLanding(tester, initialPage: 2);
    unawaited(
      showModalBottomSheet<void>(
        context: tester.element(find.text('page 2')),
        builder: (_) => const Text('open sheet'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('open sheet'), findsOneWidget);

    cubit.offer(travelIntent);
    await tester.pumpAndSettle();

    expect(find.text('open sheet'), findsNothing);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('an intent pending before mount is consumed on the first frame', (
    tester,
  ) async {
    await startSession(tester);
    cubit.offer(questIntent);

    await pumpLanding(tester, initialPage: 4);
    await tester.pumpAndSettle();

    expect(find.text('page 0'), findsOneWidget);
    expect(cubit.state.pending, isNull);
    expect(poppedUp, [questIntent]);
  });

  test('Phase 5 registers no notification popup', () {
    expect(defaultNotificationPopups, isEmpty);
  });
}
