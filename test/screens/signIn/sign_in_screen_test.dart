import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/legal_documents.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/screens/signIn/components/legal_consent_row.dart';
import 'package:klimmeck_guide/screens/signIn/consentCubit/legal_consent_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes/in_memory_legal_consent_store.dart';
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
const _accountDeletedNotice = 'Il tuo account è stato eliminato.';
const _notFollowingMessage =
    'Non sei ancora un avventuriero sul canale di LordReavor! '
    'Segui prima il canale per accedere al gioco';
const _channelLabel = 'Vai al canale di LordReavor';
const _consentSentence =
    "Accetto i Termini di servizio e l'Informativa sulla privacy";
const _consentVersion = 'v-test';
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

  /// Di default il consenso è già ricordato: i casi del login partono spuntati.
  Future<void> pumpScreen(
    WidgetTester tester, {
    SignInNotice notice = SignInNotice.none,
    bool isConsentAccepted = true,
    String? rememberedVersion,
  }) async {
    final store = InMemoryLegalConsentStore(
      acceptedVersion:
          rememberedVersion ?? (isConsentAccepted ? _consentVersion : null),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => SignInCubit(service, links)),
            BlocProvider(
              create: (_) =>
                  LegalConsentCubit(store, version: _consentVersion)..restore(),
            ),
          ],
          child: SignInScreen(notice: notice),
        ),
      ),
    );
    await tester.pump();
  }

  final loginButton = find.widgetWithText(InkWell, _loginLabel);
  final consentBox = find.byType(Checkbox);

  bool isTicked(WidgetTester tester) =>
      tester.widget<Checkbox>(consentBox).value ?? false;

  testWidgets('renders app bar without title or back, CTA and the consent '
      'row, no footer links (D-07)', (tester) async {
    await pumpScreen(tester);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.title, isNull);
    expect(appBar.automaticallyImplyLeading, isFalse);
    expect(find.text(_loginLabel), findsOneWidget);
    expect(find.text(_consentSentence, findRichText: true), findsOneWidget);
    expect(consentBox, findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Privacy'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('the consent row sits above the login button (D-07)', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      tester.getTopLeft(find.byType(LegalConsentRow)).dy,
      lessThan(tester.getTopLeft(loginButton).dy),
    );
  });

  testWidgets('the login is disabled while the box is empty (D-07)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, isConsentAccepted: false);

    await tester.tap(loginButton, warnIfMissed: false);
    await tester.pump();

    verifyNever(() => service.login());
    expect(tester.widget<InkWell>(loginButton).onTap, isNull);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_loginLabel).first),
      containsSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('ticking the box enables the login (D-07)', (tester) async {
    when(() => service.login()).thenAnswer((_) async {});
    await pumpScreen(tester, isConsentAccepted: false);

    await tester.tap(consentBox);
    await tester.pump();
    await tester.tap(loginButton);
    await tester.pump();

    expect(isTicked(tester), isTrue);
    verify(() => service.login()).called(1);
  });

  testWidgets('tapping Termini di servizio opens the terms and does not tick '
      '(D-07, D-08)', (tester) async {
    await pumpScreen(tester, isConsentAccepted: false);

    await tester.tapOnText(find.textRange.ofSubstring('Termini di servizio'));
    await tester.pump();

    expect(links.opened, [LegalDocuments.termsUri]);
    expect(isTicked(tester), isFalse);
  });

  testWidgets('tapping Informativa sulla privacy opens the privacy and does '
      'not tick (D-07, D-08)', (tester) async {
    await pumpScreen(tester, isConsentAccepted: false);

    await tester.tapOnText(
      find.textRange.ofSubstring('Informativa sulla privacy'),
    );
    await tester.pump();

    expect(links.opened, [LegalDocuments.privacyUri]);
    expect(isTicked(tester), isFalse);
  });

  testWidgets('tapping the rest of the sentence toggles the box (D-07)', (
    tester,
  ) async {
    await pumpScreen(tester, isConsentAccepted: false);

    await tester.tapOnText(find.textRange.ofSubstring('Accetto i '));
    await tester.pump();
    expect(isTicked(tester), isTrue);

    await tester.tapOnText(find.textRange.ofSubstring('Accetto i '));
    await tester.pump();
    expect(isTicked(tester), isFalse);
    expect(links.opened, isEmpty);
  });

  testWidgets('the checkbox and the two links are announced on their own '
      '(D-07)', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, isConsentAccepted: false);

    expect(
      tester.getSemantics(find.byType(Checkbox)),
      containsSemantics(label: _consentSentence, hasCheckedState: true),
    );
    for (final wording in [
      'Termini di servizio',
      'Informativa sulla privacy',
    ]) {
      final link = find.semantics.byLabel(wording);
      expect(link, findsOne);
      expect(link.evaluate().single, containsSemantics(isLink: true));
    }
    semantics.dispose();
  });

  testWidgets('a remembered acceptance starts ticked (D-10)', (tester) async {
    await pumpScreen(tester, rememberedVersion: _consentVersion);

    expect(isTicked(tester), isTrue);
  });

  testWidgets('another remembered version starts unticked (D-12)', (
    tester,
  ) async {
    await pumpScreen(tester, rememberedVersion: 'v-old');

    expect(isTicked(tester), isFalse);
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

  testWidgets('shows the account-deleted notice only when requested (D-03)', (
    tester,
  ) async {
    await pumpScreen(tester, notice: SignInNotice.accountDeleted);
    expect(find.text(_accountDeletedNotice), findsOneWidget);
    expect(find.text(_expiredNotice), findsNothing);
    expect(
      tester.getTopLeft(find.text(_accountDeletedNotice)).dy,
      lessThan(tester.getTopLeft(loginButton).dy),
    );

    await pumpScreen(tester);
    await tester.pump();
    expect(find.text(_accountDeletedNotice), findsNothing);
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
    await tester.pumpAndSettle();
    expect(find.text(_accessLostNotice), findsNothing);
    expect(find.text(_channelLabel), findsNothing);
  });

  testWidgets('the lost-access invitation sits where the not-following one '
      'does, under the login button', (tester) async {
    await pumpScreen(tester, notice: SignInNotice.channelAccessLost);
    final lostAccessText = tester.getRect(find.text(_accessLostNotice));
    final lostAccessButton = tester.getRect(find.text(_channelLabel));
    final login = tester.getRect(loginButton);
    expect(lostAccessText.top, greaterThan(login.bottom));

    when(() => service.login()).thenThrow(const LoginNotFollowingException());
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(tester.getRect(loginButton), login);
    expect(
      tester.getRect(find.text(_notFollowingMessage)).top,
      lostAccessText.top,
    );
    expect(tester.getRect(find.text(_channelLabel)), lostAccessButton);
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
