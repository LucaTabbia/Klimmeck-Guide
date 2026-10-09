import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const _expiredNotice = 'La sessione è scaduta, accedi di nuovo.';
const _manualSignIn = 'Accedi manualmente';

User _user(String id) => User(
  id: id,
  twitchId: 'twitch-$id',
  twitchPoints: 0,
  currentCharacter: null,
  role: RoleType.adventurer,
);

AuthAuthenticated _authenticated(String id, {String token = 'token'}) =>
    AuthAuthenticated(user: _user(id), accessToken: token);

/// Cubit spia creato dal builder autenticato: rivela creazione e chiusura del
/// sotto-albero della sessione.
class _SessionSpyCubit extends Cubit<String> {
  _SessionSpyCubit(super.userId);
}

void main() {
  late MockAuthTokenService service;
  late StreamController<AuthState> authStates;
  late AuthCubit authCubit;
  late SplashCubit splashCubit;
  late List<_SessionSpyCubit> createdSpies;

  setUp(() {
    service = MockAuthTokenService();
    authStates = StreamController<AuthState>.broadcast();
    when(() => service.authStateStream).thenAnswer((_) => authStates.stream);
    when(() => service.initialize()).thenAnswer((_) async {});
    authCubit = AuthCubit(service);
    splashCubit = SplashCubit(MockKlimmeckRest());
    createdSpies = [];
  });

  tearDown(() async {
    await authCubit.close();
    await splashCubit.close();
    await authStates.close();
  });

  Widget authenticatedBuilder(BuildContext context, User user) {
    return BlocProvider(
      lazy: false,
      create: (_) {
        final spy = _SessionSpyCubit(user.id);
        createdSpies.add(spy);
        return spy;
      },
      child: Text('home ${user.id}'),
    );
  }

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthTokenService>.value(
        value: service,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<SplashCubit>.value(value: splashCubit),
          ],
          child: buildTestApp(
            home: AuthGate(authenticatedBuilder: authenticatedBuilder),
          ),
        ),
      ),
    );
    await authCubit.start();
    await tester.pump();
  }

  Future<void> emitAuth(WidgetTester tester, AuthState state) async {
    authStates.add(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('bootstrapping shows the splash as cold start gate', (
    tester,
  ) async {
    await pumpGate(tester);

    final splash = tester.widget<SplashScreen>(find.byType(SplashScreen));
    expect(splash.watchConnection, isTrue);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('signed out shows the sign-in screen without notice', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, const AuthUnauthenticated());

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
  });

  testWidgets('session expired shows the sign-in screen with notice', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(
      tester,
      const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
    );

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(_expiredNotice), findsOneWidget);
  });

  testWidgets('session expired then signed out ends on the final state', (
    tester,
  ) async {
    await pumpGate(tester);
    authStates
      ..add(
        const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
      )
      ..add(const AuthUnauthenticated());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
  });

  testWidgets('authenticated shows the authenticated subtree for the user', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));

    expect(find.text('home A'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('account switch disposes the previous session subtree', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));
    final spyA = createdSpies.single;

    await emitAuth(tester, const AuthUnauthenticated());
    await emitAuth(tester, _authenticated('B'));

    expect(spyA.isClosed, isTrue);
    expect(createdSpies, hasLength(2));
    expect(createdSpies.last.state, 'B');
    expect(createdSpies.last.isClosed, isFalse);
    expect(find.text('home B'), findsOneWidget);
  });

  testWidgets('same user re-emitted keeps the session subtree', (tester) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));
    await emitAuth(tester, _authenticated('A', token: 'rotated'));

    expect(createdSpies, hasLength(1));
    expect(createdSpies.single.isClosed, isFalse);
  });

  testWidgets('going unauthenticated closes dialogs on the root navigator', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));
    unawaited(
      showDialog<void>(
        context: tester.element(find.text('home A')),
        builder: (_) => const AlertDialog(content: Text('session dialog')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('session dialog'), findsOneWidget);

    await emitAuth(tester, const AuthUnauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('session dialog'), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  Future<void> openSessionDialog(WidgetTester tester, String userId) async {
    unawaited(
      showDialog<void>(
        context: tester.element(find.text('home $userId')),
        builder: (_) => const AlertDialog(content: Text('session dialog')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('session dialog'), findsOneWidget);
  }

  testWidgets('a change of user closes the previous user dialogs', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));
    await openSessionDialog(tester, 'A');

    await emitAuth(tester, _authenticated('B'));
    await tester.pumpAndSettle();

    expect(find.text('session dialog'), findsNothing);
    expect(find.text('home B'), findsOneWidget);
  });

  testWidgets('a token rotation for the same user keeps dialogs open', (
    tester,
  ) async {
    await pumpGate(tester);
    await emitAuth(tester, _authenticated('A'));
    await openSessionDialog(tester, 'A');

    await emitAuth(tester, _authenticated('A', token: 'rotated'));
    await tester.pumpAndSettle();

    expect(find.text('session dialog'), findsOneWidget);
  });

  testWidgets('manual sign-in after the connection hint opens the sign-in', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.pump(SplashCubit.connectionHintDelay);

    expect(find.text(_manualSignIn), findsOneWidget);

    await tester.tap(find.text(_manualSignIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
  });

  testWidgets('a late successful bootstrap still enters the session', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.pump(SplashCubit.connectionHintDelay);
    expect(find.text(_manualSignIn), findsOneWidget);

    await emitAuth(tester, _authenticated('A'));

    expect(find.text('home A'), findsOneWidget);
  });

  group('character gained', () {
    var builds = 0;

    Future<void> pumpCountingGate(WidgetTester tester) async {
      builds = 0;
      await tester.pumpWidget(
        RepositoryProvider<AuthTokenService>.value(
          value: service,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<SplashCubit>.value(value: splashCubit),
            ],
            child: buildTestApp(
              home: AuthGate(
                authenticatedBuilder: (context, user) {
                  builds++;
                  return Text(
                    'home ${user.id} ${user.currentCharacter?.id ?? 'none'}',
                  );
                },
              ),
            ),
          ),
        ),
      );
      await authCubit.start();
      await tester.pump();
    }

    AuthAuthenticated withCharacter({int twitchPoints = 0}) =>
        AuthAuthenticated(
          user: _user('u1').copyWith(
            twitchPoints: twitchPoints,
            currentCharacter: Character.fromJson({'id': 'c1'}),
          ),
          accessToken: 'token',
        );

    testWidgets('the same user gaining a character rebuilds the subtree', (
      tester,
    ) async {
      await pumpCountingGate(tester);
      await emitAuth(tester, _authenticated('u1'));
      expect(find.text('home u1 none'), findsOneWidget);

      await emitAuth(tester, withCharacter());

      expect(find.text('home u1 c1'), findsOneWidget);
    });

    testWidgets('a points-only change does not rebuild the subtree', (
      tester,
    ) async {
      await pumpCountingGate(tester);
      await emitAuth(tester, _authenticated('u1'));
      await emitAuth(tester, withCharacter());
      final buildsBefore = builds;

      await emitAuth(tester, withCharacter(twitchPoints: 50));

      expect(builds, buildsBefore);
    });

    testWidgets('gaining a character keeps root dialogs open', (tester) async {
      await pumpCountingGate(tester);
      await emitAuth(tester, _authenticated('u1'));
      await openSessionDialog(tester, 'u1 none');

      await emitAuth(tester, withCharacter());
      await tester.pumpAndSettle();

      expect(find.text('session dialog'), findsOneWidget);
      expect(find.text('home u1 c1'), findsOneWidget);
    });
  });
}
