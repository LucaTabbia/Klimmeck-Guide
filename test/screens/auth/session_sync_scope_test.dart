import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/session_terminator.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/session_sync_scope.dart';
import 'package:klimmeck_guide/screens/auth/syncCubit/session_sync_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockKlimmeckGraphQl api;
  late MockAuthTokenService auth;
  late MockSessionTerminator terminator;
  late AppLifecycleEventBus lifecycle;
  late StreamController<User> userStream;
  late StreamController<bool> connection;
  late int opens;

  setUpAll(() {
    registerFallbackValue(buildTestUser());
    registerFallbackValue(UnauthenticatedReason.syncLost);
  });

  setUp(() {
    api = MockKlimmeckGraphQl();
    auth = MockAuthTokenService();
    terminator = MockSessionTerminator();
    lifecycle = AppLifecycleEventBus();
    opens = 0;
    userStream = StreamController<User>();
    connection = StreamController<bool>();
    when(() => api.subscribeToUser()).thenAnswer((_) => userStream.stream);
    when(() => api.getMe()).thenAnswer((_) async => buildTestUser());
    when(() => auth.adoptUser(any())).thenReturn(true);
    when(() => terminator.terminateSession(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await lifecycle.close();
    if (!userStream.isClosed) await userStream.close();
    if (!connection.isClosed) await connection.close();
  });

  Widget scope({Widget? child}) => RepositoryProvider<AuthTokenService>.value(
    value: auth,
    child: RepositoryProvider<AppLifecycleEvents>.value(
      value: lifecycle,
      child: SessionSyncScope(
        graphQl: api,
        terminator: terminator,
        openConnectionStream: () {
          opens++;
          return connection.stream;
        },
        child: child ?? const SizedBox(),
      ),
    ),
  );

  Widget unmounted() => const SizedBox();

  testWidgets('opens the user subscription and the socket eagerly', (
    tester,
  ) async {
    await tester.pumpWidget(scope());

    verify(() => api.subscribeToUser()).called(1);
    expect(opens, 1);
  });

  testWidgets('exposes health, refresh requests and the cubit to the child', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      scope(
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(captured.read<SyncHealth>(), isNotNull);
    expect(captured.read<UserRefreshRequests>(), isNotNull);
    expect(captured.read<SessionSyncCubit>(), isNotNull);
  });

  testWidgets('adopts a user event into the session', (tester) async {
    final user = buildTestUserWithCharacter();
    await tester.pumpWidget(scope());

    userStream.add(user);
    await tester.pump();

    verify(() => auth.adoptUser(user)).called(1);
  });

  testWidgets('ends the session once after 3 minutes of degradation', (
    tester,
  ) async {
    await tester.pumpWidget(scope());

    connection.add(false);
    await tester.pump();
    await tester.pump(const Duration(minutes: 3));
    await tester.pump(const Duration(minutes: 3));

    verify(
      () => terminator.terminateSession(UnauthenticatedReason.syncLost),
    ).called(1);
  });

  testWidgets('never ends the session while healthy and idle', (tester) async {
    await tester.pumpWidget(scope());

    connection.add(true);
    await tester.pump();
    await tester.pump(const Duration(minutes: 10));

    verifyNever(() => terminator.terminateSession(any()));
  });

  testWidgets('unmounting drops every listener and the watchdog', (
    tester,
  ) async {
    await tester.pumpWidget(scope());
    connection.add(false);
    await tester.pump();

    await tester.pumpWidget(unmounted());
    await tester.pump(const Duration(minutes: 10));

    expect(userStream.hasListener, isFalse);
    expect(connection.hasListener, isFalse);
    verifyNever(() => terminator.terminateSession(any()));
  });

  testWidgets('a new session mounts fresh streams', (tester) async {
    await tester.pumpWidget(scope());
    await tester.pumpWidget(unmounted());

    await tester.pumpWidget(scope());

    verify(() => api.subscribeToUser()).called(2);
    expect(opens, 2);
  });

  testWidgets('a refresh request refetches the user', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      scope(
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );

    captured.read<UserRefreshRequests>().requestUserRefresh();
    await tester.pump();

    verify(() => api.getMe()).called(1);
  });
}
