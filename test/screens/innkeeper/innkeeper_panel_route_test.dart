import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/fake_server_clock_service.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

final DateTime _now = DateTime.utc(2026, 10, 29, 12);

AuthAuthenticated _sessionAs(RoleType? role) => AuthAuthenticated(
  user: User(
    id: testUserId,
    twitchId: testTwitchId,
    twitchPoints: 0,
    currentCharacter: null,
    role: role,
  ),
  accessToken: testAccessToken,
);

void main() {
  group('isInnkeeperSession', () {
    test('an innkeeper session is the GM', () {
      expect(
        isInnkeeperSession(
          AuthAuthenticated(
            user: buildTestUser(role: RoleType.innkeeper),
            accessToken: testAccessToken,
          ),
        ),
        isTrue,
      );
    });

    test('adventurer, guard and a null role are not', () {
      for (final role in [RoleType.adventurer, RoleType.guard, null]) {
        expect(isInnkeeperSession(_sessionAs(role)), isFalse, reason: '$role');
      }
    });

    test('a signed-out session is not', () {
      expect(isInnkeeperSession(const AuthUnauthenticated()), isFalse);
    });
  });

  group('openInnkeeperPanel', () {
    late MockAuthCubit authCubit;
    late StreamController<AuthState> authStates;
    late MockInnkeeperRepository repository;
    late StreamController<List<PendingRequest>> queue;
    late MockTeleportModeCubit teleportCubit;

    setUp(() {
      teleportCubit = MockTeleportModeCubit();
      whenListen(
        teleportCubit,
        const Stream<TeleportModeState>.empty(),
        initialState: const TeleportIdle(),
      );
      when(
        () => teleportCubit.prepare(
          characterId: any(named: 'characterId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async {});
      authCubit = MockAuthCubit();
      authStates = StreamController<AuthState>.broadcast();
      whenListen(
        authCubit,
        authStates.stream,
        initialState: _sessionAs(RoleType.innkeeper),
      );
      repository = MockInnkeeperRepository();
      queue = StreamController<List<PendingRequest>>();
      when(() => repository.watchQueue()).thenAnswer((_) => queue.stream);
      when(() => repository.fetchQueue()).thenAnswer((_) async => const []);
    });

    tearDown(() async {
      await authStates.close();
    });

    Future<void> pumpAndOpen(WidgetTester tester) async {
      useLandscapePhone(tester);
      await tester.pumpWidget(
        RepositoryProvider<AppLifecycleEvents>.value(
          value: AppLifecycleEventBus(),
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: buildTestApp(
              home: RepositoryProvider<InnkeeperRepository>.value(
                value: repository,
                child: RepositoryProvider<ServerClockService>.value(
                  value: FakeServerClockService(_now),
                  child: BlocProvider<TeleportModeCubit>.value(
                    value: teleportCubit,
                    child: Scaffold(
                      body: Builder(
                        builder: (context) => ElevatedButton(
                          onPressed: () => openInnkeeperPanel(context),
                          child: const Text('open'),
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
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('pushes the panel with its own live queue', (tester) async {
      await pumpAndOpen(tester);

      expect(find.byType(InnkeeperPanelScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      verify(() => repository.watchQueue()).called(1);
    });

    testWidgets('a row «Teletrasporta» reaches the shell teleport mode', (
      tester,
    ) async {
      await pumpAndOpen(tester);
      queue.add([PendingRequest.fromJson(pendingRequestJson())]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Teletrasporta'));
      await tester.pump();

      verify(
        () => teleportCubit.prepare(characterId: 'char-aldo', name: 'Aldo'),
      ).called(1);
    });

    testWidgets('popping the panel cancels the queue subscription', (
      tester,
    ) async {
      await pumpAndOpen(tester);
      expect(queue.hasListener, isTrue);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      expect(queue.hasListener, isFalse);
    });

    testWidgets('a FORBIDDEN queue closes the panel with the SnackBar', (
      tester,
    ) async {
      await pumpAndOpen(tester);

      queue.addError(
        const SubscriptionStreamException(
          operation: 'pendingRequestsUpdated',
          code: 'FORBIDDEN',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      expect(
        find.text(InnkeeperPanelScreen.unavailableMessage),
        findsOneWidget,
      );
    });

    testWidgets('a lost innkeeper role closes the panel silently', (
      tester,
    ) async {
      await pumpAndOpen(tester);

      authStates.add(_sessionAs(RoleType.adventurer));
      await tester.pumpAndSettle();

      expect(find.byType(InnkeeperPanelScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
