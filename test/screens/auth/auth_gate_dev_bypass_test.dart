import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/dev_auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/dev_auth_env.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const _loginLabel = 'Login con Twitch';
const _devUserId = 'user-test-id';

/// Success Criterion 7: con il bypass dev (nessuna chiave Twitch) l'intero ciclo
/// cold start → logout → login passa dal vero `DevAuthTokenService`.
void main() {
  late DevAuthTokenService service;
  late AuthCubit authCubit;
  late MockSplashCubit splashCubit;
  late int teardownCalls;

  setUp(() {
    teardownCalls = 0;
    splashCubit = MockSplashCubit();
    whenListen(
      splashCubit,
      const Stream<SplashState>.empty(),
      initialState: const SplashInitial(),
    );
    when(() => splashCubit.startBootstrapWatch()).thenReturn(null);
    when(() => splashCubit.stopBootstrapWatch()).thenReturn(null);
  });

  tearDown(() async {
    await authCubit.close();
    service.dispose();
  });

  Future<void> coldStart(WidgetTester tester) async {
    service = DevAuthTokenService(
      onSessionTeardown: () async => teardownCalls++,
    );
    authCubit = AuthCubit(service);
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
              authenticatedBuilder: (_, user) => Text('home ${user.id}'),
            ),
          ),
        ),
      ),
    );
    await authCubit.start();
    await tester.pump();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('cold start goes straight into the authenticated session', (
    tester,
  ) async {
    await loadTestEnv();
    await coldStart(tester);

    expect(find.text('home $_devUserId'), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('logout shows sign-in and Twitch login re-enters instantly', (
    tester,
  ) async {
    await loadTestEnv();
    await coldStart(tester);

    await authCubit.logout();
    await settle(tester);

    expect(teardownCalls, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('home $_devUserId'), findsNothing);

    await tester.tap(find.text(_loginLabel));
    await settle(tester);

    expect(find.text('home $_devUserId'), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('start signed out flag cold starts on the sign-in screen', (
    tester,
  ) async {
    await loadTestEnv(startSignedOut: 'true');
    await coldStart(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.textContaining('home'), findsNothing);
  });
}
