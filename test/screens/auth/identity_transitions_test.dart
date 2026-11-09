import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';
import 'package:klimmeck_guide/screens/auth/session_sync_scope.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

/// Cubit spia della pagina di creazione: rivela creazione e chiusura.
class _CreationSpyCubit extends Cubit<int> {
  _CreationSpyCubit() : super(0);
}

/// Cubit spia della shell, uno per personaggio.
class _ShellSpyCubit extends Cubit<String> {
  _ShellSpyCubit(super.characterId);
}

void main() {
  late MockAuthTokenService service;
  late StreamController<AuthState> authStates;
  late AuthCubit authCubit;
  late SplashCubit splashCubit;
  late MockKlimmeckGraphQl graphQl;
  late MockSessionTerminator terminator;
  late AppLifecycleEventBus lifecycle;
  late StreamController<bool> connection;
  late List<StreamController<User>> userStreams;
  late List<_CreationSpyCubit> creationSpies;
  late List<_ShellSpyCubit> shellSpies;

  final userB = buildTestUserWithCharacter(
    characterId: 'character-b',
  ).copyWith(id: 'user-b', twitchId: 'twitch-b');

  setUpAll(() {
    registerFallbackValue(buildTestUser());
    registerFallbackValue(UnauthenticatedReason.syncLost);
  });

  setUp(() {
    creationSpies = [];
    shellSpies = [];
    userStreams = [];
    authStates = StreamController<AuthState>.broadcast();
    service = MockAuthTokenService();
    when(() => service.authStateStream).thenAnswer((_) => authStates.stream);
    when(() => service.initialize()).thenAnswer((_) async {});
    when(() => service.adoptUser(any())).thenAnswer((invocation) {
      final user = invocation.positionalArguments.single as User;
      authStates.add(AuthAuthenticated(user: user, accessToken: 'token'));
      return true;
    });
    authCubit = AuthCubit(service);
    splashCubit = SplashCubit(MockKlimmeckRest());
    graphQl = MockKlimmeckGraphQl();
    when(() => graphQl.subscribeToUser()).thenAnswer((_) {
      final updates = StreamController<User>.broadcast();
      userStreams.add(updates);
      return updates.stream;
    });
    when(() => graphQl.getMe()).thenAnswer((_) async => buildTestUser());
    terminator = MockSessionTerminator();
    when(() => terminator.terminateSession(any())).thenAnswer((_) async {});
    lifecycle = AppLifecycleEventBus();
    connection = StreamController<bool>.broadcast();
  });

  tearDown(() async {
    await authCubit.close();
    await splashCubit.close();
    await authStates.close();
    await lifecycle.close();
    await connection.close();
    for (final updates in userStreams) {
      await updates.close();
    }
  });

  Widget creationPage(BuildContext context) => BlocProvider(
    lazy: false,
    create: (_) {
      final spy = _CreationSpyCubit();
      creationSpies.add(spy);
      return spy;
    },
    child: const Text('creation'),
  );

  Widget shell(BuildContext context, String characterId) => BlocProvider(
    lazy: false,
    create: (_) {
      final spy = _ShellSpyCubit(characterId);
      shellSpies.add(spy);
      return spy;
    },
    child: Text('shell $characterId'),
  );

  Widget session(BuildContext context, User user) => SessionSyncScope(
    graphQl: graphQl,
    terminator: terminator,
    openConnectionStream: () => connection.stream,
    child: SessionHome(
      user: user,
      creationBuilder: creationPage,
      shellBuilder: shell,
    ),
  );

  Future<void> pumpSignedIn(WidgetTester tester, User user) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthTokenService>.value(value: service),
          RepositoryProvider<AppLifecycleEvents>.value(value: lifecycle),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<SplashCubit>.value(value: splashCubit),
          ],
          child: buildTestApp(home: AuthGate(authenticatedBuilder: session)),
        ),
      ),
    );
    await authCubit.start();
    authStates.add(AuthAuthenticated(user: user, accessToken: 'token'));
    await tester.pumpAndSettle();
  }

  Future<void> pushUserUpdate(WidgetTester tester, User user) async {
    userStreams.last.add(user);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a character removed from another device opens the creation page with a fresh cubit (D-11)',
    (tester) async {
      await pumpSignedIn(tester, buildTestUserWithCharacter(characterId: 'c1'));
      expect(find.text('shell c1'), findsOneWidget);

      await pushUserUpdate(tester, buildTestUser());

      expect(find.text('creation'), findsOneWidget);
      expect(find.text('shell c1'), findsNothing);
      expect(shellSpies.single.isClosed, isTrue);
      expect(creationSpies.single.isClosed, isFalse);
    },
  );

  testWidgets(
    'a character recreated elsewhere opens a new shell for the new id (D-11)',
    (tester) async {
      await pumpSignedIn(tester, buildTestUserWithCharacter(characterId: 'c1'));
      await pushUserUpdate(tester, buildTestUser());

      await pushUserUpdate(
        tester,
        buildTestUserWithCharacter(characterId: 'c2'),
      );

      expect(
        find.byKey(const ValueKey<String>('character:c2')),
        findsOneWidget,
      );
      expect(find.text('shell c2'), findsOneWidget);
      expect(creationSpies.single.isClosed, isTrue);
      expect(shellSpies, hasLength(2));
      expect(shellSpies.last, isNot(same(shellSpies.first)));
      expect(shellSpies.first.isClosed, isTrue);
      expect(shellSpies.last.state, 'c2');
      expect(shellSpies.last.isClosed, isFalse);
    },
  );

  testWidgets(
    'a root dialog open on the old character is closed on the change (D-11)',
    (tester) async {
      await pumpSignedIn(tester, buildTestUserWithCharacter(characterId: 'c1'));
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('shell c1')),
          builder: (_) => const AlertDialog(content: Text('c1 dialog')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('c1 dialog'), findsOneWidget);

      await pushUserUpdate(
        tester,
        buildTestUserWithCharacter(characterId: 'c2'),
      );

      expect(find.text('c1 dialog'), findsNothing);
      expect(find.text('shell c2'), findsOneWidget);
      expect(shellSpies.first.isClosed, isTrue);
    },
  );

  testWidgets('an account switch replaces the whole session subtree (D-11)', (
    tester,
  ) async {
    await pumpSignedIn(tester, buildTestUserWithCharacter());
    final sessionA = userStreams.single;

    authStates.add(AuthAuthenticated(user: userB, accessToken: 'token-b'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>(testUserId)), findsNothing);
    expect(find.byKey(ValueKey<String>(userB.id)), findsOneWidget);
    expect(sessionA.hasListener, isFalse);
    expect(userStreams, hasLength(2));
    expect(userStreams.last.hasListener, isTrue);
    expect(shellSpies.first.isClosed, isTrue);
    expect(shellSpies.last.state, 'character-b');
    expect(shellSpies.last.isClosed, isFalse);
  });
}
