import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const _connectionHint =
    'Connessione instabile, attendere o accedere manualmente';
const _manualSignIn = 'Accedi manualmente';

void main() {
  late MockSplashCubit cubit;

  setUp(() {
    cubit = MockSplashCubit();
    when(() => cubit.startBootstrapWatch()).thenReturn(null);
    when(() => cubit.stopBootstrapWatch()).thenReturn(null);
  });

  Future<void> pumpSplash(
    WidgetTester tester, {
    required SplashState state,
    bool watchConnection = true,
    VoidCallback? onManualSignIn,
  }) async {
    whenListen(cubit, const Stream<SplashState>.empty(), initialState: state);
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<SplashCubit>.value(
          value: cubit,
          child: SplashScreen(
            watchConnection: watchConnection,
            onManualSignIn: onManualSignIn,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the animated loading text without chrome while waiting', (
    tester,
  ) async {
    await pumpSplash(tester, state: const SplashInitial());

    expect(find.textContaining('Caricamento'), findsOneWidget);
    expect(find.text(_manualSignIn), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the loading text stays still while its dots come and go', (
    tester,
  ) async {
    await pumpSplash(tester, state: const SplashInitial());
    final loadingText = find.textContaining('Caricamento');
    final still = tester.getRect(loadingText);

    for (var dots = 2; dots <= 4; dots++) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(tester.getRect(loadingText), still);
    }
  });

  testWidgets('the whole sign fits on the screen, clear of the loading text', (
    tester,
  ) async {
    await pumpSplash(tester, state: const SplashInitial());

    final sign = find.image(const AssetImage('assets/images/splashSign.png'));
    expect(tester.widget<Image>(sign).fit, BoxFit.contain);
    final signRect = tester.getRect(sign);
    final textRect = tester.getRect(find.textContaining('Caricamento'));
    expect(signRect.top, greaterThanOrEqualTo(16));
    expect(signRect.bottom, lessThan(textRect.top));
  });

  testWidgets('shows the download percentage under the loading text', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      state: const SplashPreloading(42),
      watchConnection: false,
    );

    final loadingRect = tester.getRect(find.textContaining('Caricamento'));
    final percentRect = tester.getRect(find.text('42%'));
    expect(percentRect.top, greaterThanOrEqualTo(loadingRect.bottom));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the sign and the loading text do not move when the percentage '
      'appears', (tester) async {
    final states = StreamController<SplashState>();
    addTearDown(states.close);
    whenListen(cubit, states.stream, initialState: const SplashInitial());
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<SplashCubit>.value(
          value: cubit,
          child: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();
    final sign = find.image(const AssetImage('assets/images/splashSign.png'));
    final loadingText = find.textContaining('Caricamento');
    final signBefore = tester.getRect(sign);
    final textBefore = tester.getRect(loadingText);

    states.add(const SplashPreloading(42));
    await tester.pump();
    await tester.pump();

    expect(find.text('42%'), findsOneWidget);
    expect(tester.getRect(sign), signBefore);
    expect(tester.getRect(loadingText), textBefore);
  });

  testWidgets('shows no percentage before the download starts', (tester) async {
    await pumpSplash(tester, state: const SplashInitial());

    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('shows the connection hint and manual sign-in when delayed', (
    tester,
  ) async {
    var manualSignInTaps = 0;
    await pumpSplash(
      tester,
      state: const SplashNetworkDelayed(),
      onManualSignIn: () => manualSignInTaps++,
    );

    expect(find.text(_connectionHint), findsOneWidget);
    expect(find.text(_manualSignIn), findsOneWidget);
    expect(find.textContaining('Caricamento'), findsNothing);

    await tester.tap(find.text(_manualSignIn));
    await tester.pump();

    expect(manualSignInTaps, 1);
  });

  testWidgets('hides the connection hint when not watching the connection', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      state: const SplashNetworkDelayed(),
      watchConnection: false,
    );

    expect(find.text(_connectionHint), findsNothing);
    expect(find.text(_manualSignIn), findsNothing);
    verifyNever(() => cubit.startBootstrapWatch());
  });

  testWidgets('starts the watch on init and stops it on dispose', (
    tester,
  ) async {
    await pumpSplash(tester, state: const SplashInitial());

    verify(() => cubit.startBootstrapWatch()).called(1);
    verifyNever(() => cubit.stopBootstrapWatch());

    await tester.pumpWidget(const SizedBox.shrink());

    verify(() => cubit.stopBootstrapWatch()).called(1);
  });

  testWidgets('does not preload remote images on its own', (tester) async {
    await pumpSplash(tester, state: const SplashInitial());

    verifyNever(() => cubit.getImages(any()));
  });
}
