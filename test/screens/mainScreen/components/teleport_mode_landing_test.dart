import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/teleport_mode_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

const TeleportTarget _bea = TeleportTarget(
  characterId: 'char-bea',
  name: 'Bea',
  location: PointOfInterest(
    id: 'city-marker-1',
    type: null,
    location: LatLng(10, 20),
    city: null,
    quest: null,
  ),
  sex: SexType.female,
);

AuthAuthenticated _sessionAs(RoleType role) => AuthAuthenticated(
  user: buildTestUser(role: role),
  accessToken: testAccessToken,
);

/// Phase 10 ADMIN-04 (10-CONTEXT D-15/D-17): la shell segue la modalità
/// teletrasporto del GM.
void main() {
  late MockTeleportModeCubit teleportCubit;
  late StreamController<TeleportModeState> teleportStates;
  late MockAuthCubit authCubit;
  late StreamController<AuthState> authStates;
  late MockInnkeeperRepository repository;
  late StreamController<List<PendingRequest>> queue;

  setUp(() {
    teleportCubit = MockTeleportModeCubit();
    teleportStates = StreamController<TeleportModeState>.broadcast();
    whenListen(
      teleportCubit,
      teleportStates.stream,
      initialState: const TeleportIdle(),
    );
    when(() => teleportCubit.cancel()).thenReturn(null);
    when(() => teleportCubit.acknowledgeSuccess()).thenReturn(null);
    authCubit = MockAuthCubit();
    authStates = StreamController<AuthState>.broadcast();
    whenListen(
      authCubit,
      authStates.stream,
      initialState: _sessionAs(RoleType.innkeeper),
    );
    repository = MockInnkeeperRepository();
    queue = StreamController<List<PendingRequest>>.broadcast();
    when(() => repository.watchQueue()).thenAnswer((_) => queue.stream);
    when(() => repository.fetchQueue()).thenAnswer((_) async => const []);
  });

  tearDown(() async {
    await teleportStates.close();
    await authStates.close();
    await queue.close();
  });

  Future<PageController> pumpLanding(WidgetTester tester) async {
    useLandscapePhone(tester);
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      RepositoryProvider<AppLifecycleEvents>.value(
        value: AppLifecycleEventBus(),
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: buildTestApp(
            home: RepositoryProvider<InnkeeperRepository>.value(
              value: repository,
              child: RepositoryProvider<ServerClockService>.value(
                value: FakeServerClockService(DateTime.utc(2026, 10, 29, 12)),
                child: BlocProvider<TeleportModeCubit>.value(
                  value: teleportCubit,
                  child: Scaffold(
                    body: TeleportModeLanding(
                      pageController: controller,
                      child: PageView(
                        controller: controller,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(7, (i) => Text('page $i')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  Future<void> pushPanelStandIn(WidgetTester tester) async {
    unawaited(
      Navigator.of(
        tester.element(find.byType(PageView)),
        rootNavigator: true,
      ).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('panel stand-in')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, TeleportModeState state) async {
    teleportStates.add(state);
    await tester.pumpAndSettle();
  }

  testWidgets('entering the mode pops the panel and lands on the map', (
    tester,
  ) async {
    final controller = await pumpLanding(tester);
    controller.jumpToPage(3);
    await tester.pump();
    await pushPanelStandIn(tester);
    expect(find.text('panel stand-in'), findsOneWidget);

    await emit(tester, const TeleportActive(target: _bea));

    expect(find.text('panel stand-in'), findsNothing);
    expect(controller.page!.round(), 0);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('entering the mode on the map keeps it and does not cancel', (
    tester,
  ) async {
    final controller = await pumpLanding(tester);

    await emit(tester, const TeleportActive(target: _bea));

    expect(controller.page!.round(), 0);
    verifyNever(() => teleportCubit.cancel());
  });

  testWidgets('a teleporting update does not land again', (tester) async {
    final controller = await pumpLanding(tester);
    await emit(tester, const TeleportActive(target: _bea));
    controller.jumpToPage(2);
    await tester.pump();

    await emit(tester, const TeleportActive(target: _bea, isTeleporting: true));

    expect(controller.page!.round(), 2);
  });

  testWidgets('a success acknowledges it and reopens the panel', (
    tester,
  ) async {
    await pumpLanding(tester);
    await emit(tester, const TeleportActive(target: _bea));

    await emit(tester, const TeleportSucceeded(target: _bea));

    verify(() => teleportCubit.acknowledgeSuccess()).called(1);
    expect(find.byType(InnkeeperPanelScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lost innkeeper role cancels the mode', (tester) async {
    await pumpLanding(tester);

    authStates.add(_sessionAs(RoleType.adventurer));
    await tester.pump();

    verify(() => teleportCubit.cancel()).called(1);
  });

  testWidgets('an adventurer staying adventurer cancels nothing', (
    tester,
  ) async {
    whenListen(
      authCubit,
      authStates.stream,
      initialState: _sessionAs(RoleType.adventurer),
    );
    await pumpLanding(tester);

    authStates.add(
      AuthAuthenticated(
        user: buildTestUser(role: RoleType.adventurer),
        accessToken: 'refreshed-token',
      ),
    );
    await tester.pump();

    verifyNever(() => teleportCubit.cancel());
  });
}
