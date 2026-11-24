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
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/innkeeper_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
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
  late MockTeleportModeCubit teleportCubit;
  late MockPlayerAccountDeletionCubit playerDeletionCubit;

  void givenPlayerDeletionState(PlayerAccountDeletionState state) => whenListen(
    playerDeletionCubit,
    const Stream<PlayerAccountDeletionState>.empty(),
    initialState: state,
  );

  setUp(() {
    teleportCubit = MockTeleportModeCubit();
    whenListen(
      teleportCubit,
      const Stream<TeleportModeState>.empty(),
      initialState: const TeleportIdle(),
    );
    playerDeletionCubit = MockPlayerAccountDeletionCubit();
    givenPlayerDeletionState(const PlayerAccountDeletionState());
    when(() => playerDeletionCubit.isClosed).thenReturn(false);
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

  Future<void> pumpSection(
    WidgetTester tester,
    AuthState initial, {
    bool isAccountDeletionEnabled = false,
  }) async {
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
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<TeleportModeCubit>.value(value: teleportCubit),
                    BlocProvider<PlayerAccountDeletionCubit>.value(
                      value: playerDeletionCubit,
                    ),
                  ],
                  child: Scaffold(
                    body: InnkeeperSection(
                      isAccountDeletionEnabled: isAccountDeletionEnabled,
                    ),
                  ),
                ),
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

  group('account deletion entry', () {
    testWidgets(
      'while the switch is off the Locanda has only Apri la Locanda (25-07 turns it on)',
      (tester) async {
        await pumpSection(tester, _sessionAs(RoleType.innkeeper));

        expect(find.text('Apri la Locanda'), findsOneWidget);
        expect(find.text('Elimina un account'), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
      },
    );

    testWidgets(
      'the innkeeper sees Elimina un account under Apri la Locanda, red outline (D-15)',
      (tester) async {
        await pumpSection(
          tester,
          _sessionAs(RoleType.innkeeper),
          isAccountDeletionEnabled: true,
        );

        final entry = find.widgetWithText(OutlinedButton, 'Elimina un account');
        expect(entry, findsOneWidget);
        expect(
          tester.widget<OutlinedButton>(entry).style,
          KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
        );
        expect(
          tester.getTopLeft(entry).dy,
          greaterThan(tester.getTopLeft(find.text('Apri la Locanda')).dy),
        );
      },
    );

    testWidgets('a player never sees the Locanda', (tester) async {
      await pumpSection(
        tester,
        _sessionAs(RoleType.adventurer),
        isAccountDeletionEnabled: true,
      );

      expect(find.text('Locanda'), findsNothing);
      expect(find.text('Elimina un account'), findsNothing);
    });

    testWidgets('Elimina un account opens the username dialog (D-15)', (
      tester,
    ) async {
      await pumpSection(
        tester,
        _sessionAs(RoleType.innkeeper),
        isAccountDeletionEnabled: true,
      );

      await tester.tap(find.text('Elimina un account'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerAccountDeletionDialog), findsOneWidget);
      verify(() => playerDeletionCubit.reset()).called(1);
    });

    testWidgets('after a success the section reads Account eliminato. (D-15)', (
      tester,
    ) async {
      givenPlayerDeletionState(
        const PlayerAccountDeletionState(hasDeleted: true),
      );
      await pumpSection(
        tester,
        _sessionAs(RoleType.innkeeper),
        isAccountDeletionEnabled: true,
      );

      final line = find.text('Account eliminato.');
      expect(line, findsOneWidget);
      expect(
        tester.getTopLeft(line).dy,
        greaterThan(tester.getTopLeft(find.text('Elimina un account')).dy),
      );
    });

    testWidgets('no success line before a deletion', (tester) async {
      await pumpSection(
        tester,
        _sessionAs(RoleType.innkeeper),
        isAccountDeletionEnabled: true,
      );

      expect(find.text('Account eliminato.'), findsNothing);
    });
  });
}
