import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const _loginLabel = 'Login con Twitch';
const _connectionError = 'Errore di connessione, riprova';
const _unavailableError = 'Login con Twitch non ancora disponibile.';
const _expiredNotice = 'La sessione è scaduta, accedi di nuovo.';

void main() {
  late MockAuthTokenService service;

  setUp(() {
    service = MockAuthTokenService();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool showSessionExpiredNotice = false,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider(
          create: (_) => SignInCubit(service),
          child: SignInScreen(
            showSessionExpiredNotice: showSessionExpiredNotice,
          ),
        ),
      ),
    );
  }

  final loginButton = find.widgetWithText(InkWell, _loginLabel);

  testWidgets('renders app bar without title or back, CTA and footer', (
    tester,
  ) async {
    await pumpScreen(tester);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.title, isNull);
    expect(appBar.automaticallyImplyLeading, isFalse);
    expect(find.text(_loginLabel), findsOneWidget);
    expect(find.text('Termini di servizio'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  testWidgets('login button carries the twitch glyph and loads it cleanly', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: loginButton, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('login button has semantics label and a 44px minimum height', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.bySemanticsLabel(_loginLabel), findsWidgets);
    expect(tester.getSize(loginButton).height, greaterThanOrEqualTo(44));
  });

  testWidgets('tap calls login and shows a spinner while waiting', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(() => service.login()).thenAnswer((_) => completer.future);
    await pumpScreen(tester);

    await tester.tap(loginButton);
    await tester.pump();

    verify(() => service.login()).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell).first).onTap, isNull);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failed login shows connection error and allows retry', (
    tester,
  ) async {
    when(() => service.login()).thenThrow(const LoginFailedException('x'));
    await pumpScreen(tester);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.text(_connectionError), findsOneWidget);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    verify(() => service.login()).called(2);
  });

  testWidgets('unavailable login shows the not-configured message only', (
    tester,
  ) async {
    when(() => service.login()).thenThrow(const LoginUnavailableException());
    await pumpScreen(tester);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(_unavailableError), findsOneWidget);
    expect(find.text(_connectionError), findsNothing);
  });

  testWidgets('cancelled login shows no error', (tester) async {
    when(() => service.login()).thenThrow(const LoginCancelledException());
    await pumpScreen(tester);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(_connectionError), findsNothing);
    expect(find.text(_unavailableError), findsNothing);
  });

  testWidgets('shows the session expired notice only when requested', (
    tester,
  ) async {
    await pumpScreen(tester, showSessionExpiredNotice: true);
    expect(find.text(_expiredNotice), findsOneWidget);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_expiredNotice), findsNothing);
  });
}
