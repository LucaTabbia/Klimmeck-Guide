import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes/recording_link_opener.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

const _loginLabel = 'Login con Twitch';
const _connectionError = 'Errore di connessione, riprova';
const _unavailableError = 'Login con Twitch non ancora disponibile.';
const _expiredNotice = 'La sessione è scaduta, accedi di nuovo.';
const _connectionLostNotice = 'Connessione persa, accedi di nuovo.';
const _newLoginNotice = 'Hai effettuato l\'accesso da un altro dispositivo.';
const _roleChangedNotice = 'Il tuo ruolo è cambiato, accedi di nuovo.';
const _notFollowingMessage =
    'Non sei ancora un avventuriero sul canale di LordReavor! '
    'Segui prima il canale per accedere al gioco';
const _channelLabel = 'Vai al canale di LordReavor';
const _accessLostNotice =
    'Non segui più il canale di LordReavor! '
    'Segui di nuovo il canale per accedere al gioco';

void main() {
  late MockAuthTokenService service;
  late RecordingLinkOpener links;

  setUp(() {
    service = MockAuthTokenService();
    links = RecordingLinkOpener();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SignInNotice notice = SignInNotice.none,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider(
          create: (_) => SignInCubit(service, links),
          child: SignInScreen(notice: notice),
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

  testWidgets('a viewer who does not follow the channel reads the invitation '
      'and reaches the channel from its button', (tester) async {
    when(() => service.login()).thenThrow(const LoginNotFollowingException());
    await pumpScreen(tester);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(_notFollowingMessage), findsOneWidget);
    expect(find.text(_connectionError), findsNothing);
    expect(links.opened, isEmpty);

    await tester.tap(find.text(_channelLabel));
    await tester.pumpAndSettle();

    expect(links.opened, [TwitchChannel.uri]);
    expect(find.text(_notFollowingMessage), findsOneWidget);
  });

  testWidgets('the channel button shows only to who does not follow', (
    tester,
  ) async {
    when(() => service.login()).thenThrow(const LoginFailedException('x'));
    await pumpScreen(tester);
    expect(find.text(_channelLabel), findsNothing);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(_channelLabel), findsNothing);
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
    await pumpScreen(tester, notice: SignInNotice.sessionExpired);
    expect(find.text(_expiredNotice), findsOneWidget);
    expect(find.text(_connectionLostNotice), findsNothing);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_expiredNotice), findsNothing);
  });

  testWidgets('shows the connection lost notice only when requested', (
    tester,
  ) async {
    await pumpScreen(tester, notice: SignInNotice.connectionLost);
    expect(find.text(_connectionLostNotice), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_connectionLostNotice), findsNothing);
  });

  testWidgets('shows the new-login notice only when requested (D-12)', (
    tester,
  ) async {
    await pumpScreen(tester, notice: SignInNotice.replacedByNewLogin);
    expect(find.text(_newLoginNotice), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
    expect(find.text(_roleChangedNotice), findsNothing);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_newLoginNotice), findsNothing);
  });

  testWidgets('who was logged out for leaving the channel reads why and '
      'reaches the channel from the notice', (tester) async {
    await pumpScreen(tester, notice: SignInNotice.channelAccessLost);

    expect(find.text(_accessLostNotice), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);

    await tester.tap(find.text(_channelLabel));
    await tester.pumpAndSettle();

    expect(links.opened, [TwitchChannel.uri]);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_accessLostNotice), findsNothing);
    expect(find.text(_channelLabel), findsNothing);
  });

  testWidgets('a refused login replaces the lost-access notice: one '
      'invitation, one channel button', (tester) async {
    when(() => service.login()).thenThrow(const LoginNotFollowingException());
    await pumpScreen(tester, notice: SignInNotice.channelAccessLost);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(_notFollowingMessage), findsOneWidget);
    expect(find.text(_accessLostNotice), findsNothing);
    expect(find.text(_channelLabel), findsOneWidget);
  });

  testWidgets('shows the role-changed notice only when requested (D-12)', (
    tester,
  ) async {
    await pumpScreen(tester, notice: SignInNotice.roleChanged);
    expect(find.text(_roleChangedNotice), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
    expect(find.text(_newLoginNotice), findsNothing);

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_roleChangedNotice), findsNothing);
  });
}
