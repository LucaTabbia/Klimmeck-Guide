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
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/innkeeper_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/auth_fixtures.dart';
import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

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
  late MockAuthCubit authCubit;
  late StreamController<AuthState> authStates;
  late MockInnkeeperRepository repository;

  setUp(() {
    authCubit = MockAuthCubit();
    authStates = StreamController<AuthState>.broadcast();
    repository = MockInnkeeperRepository();
    when(
      () => repository.watchQueue(),
    ).thenAnswer((_) => const Stream<List<PendingRequest>>.empty());
    when(() => repository.fetchQueue()).thenAnswer((_) async => const []);
  });

  tearDown(() async {
    await authStates.close();
  });

  Future<void> pumpSection(WidgetTester tester, AuthState initial) async {
    useLandscapePhone(tester);
    whenListen(authCubit, authStates.stream, initialState: initial);
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
                child: const Scaffold(body: InnkeeperSection()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('an innkeeper session shows the section and its button', (
    tester,
  ) async {
    await pumpSection(tester, _sessionAs(RoleType.innkeeper));

    expect(find.text(InnkeeperSection.title), findsOneWidget);
    expect(find.text('Apri la Locanda'), findsOneWidget);
  });

  testWidgets('adventurer, guard and a null role see nothing', (tester) async {
    for (final role in [RoleType.adventurer, RoleType.guard, null]) {
      await pumpSection(tester, _sessionAs(role));

      expect(find.text('Locanda'), findsNothing, reason: '$role');
      expect(find.text('Apri la Locanda'), findsNothing, reason: '$role');
    }
  });

  testWidgets('a signed-out session sees nothing', (tester) async {
    await pumpSection(tester, const AuthUnauthenticated());

    expect(find.text('Locanda'), findsNothing);
  });

  testWidgets('the section follows the session role live', (tester) async {
    await pumpSection(tester, _sessionAs(RoleType.adventurer));
    expect(find.text('Locanda'), findsNothing);

    authStates.add(_sessionAs(RoleType.innkeeper));
    await tester.pumpAndSettle();
    expect(find.text('Locanda'), findsOneWidget);

    authStates.add(_sessionAs(RoleType.adventurer));
    await tester.pumpAndSettle();
    expect(find.text('Locanda'), findsNothing);
  });

  testWidgets('«Apri la Locanda» opens the panel', (tester) async {
    await pumpSection(tester, _sessionAs(RoleType.innkeeper));

    await tester.tap(find.text('Apri la Locanda'));
    await tester.pumpAndSettle();

    expect(find.byType(InnkeeperPanelScreen), findsOneWidget);
  });
}
