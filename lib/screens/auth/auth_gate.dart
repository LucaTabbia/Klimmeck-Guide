import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/legal_documents.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/links/url_launcher_link_opener.dart';
import 'package:klimmeck_guide/repository/storage/legal_consent_store.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/consentCubit/legal_consent_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';

/// Guardia di routing state-driven (docs/rules/architecture.md): l'albero
/// dipende solo da [AuthCubit].
///
/// - `AuthBootstrapping` → splash come gate del cold start (D-17/D-18);
/// - `AuthUnauthenticated` → sign-in, con notice se la sessione è scaduta o la
///   connessione in tempo reale è andata persa (Phase 3 D-15); la spunta del
///   consenso legale si ripristina da [legalConsentStore] a ogni schermata di
///   sign-in, tranne all'arrivo con l'account eliminato, che la dimentica
///   (Phase 25 D-10);
/// - `AuthAuthenticated` → [authenticatedBuilder] sotto una chiave legata a
///   `user.id`: logout e cambio account sostituiscono l'intera sessione.
///   Ricostruisce anche quando lo stesso utente ottiene un personaggio
///   (creazione → shell, D-26), senza chiudere la sessione.
///
/// Quando la sessione finisce (`AuthUnauthenticated`) o cambia utente chiude
/// dialog e sheet aperti sul Navigator radice, che vivono fuori dal
/// sotto-albero della sessione. Li chiude anche quando cambia il personaggio
/// dello stesso utente (Phase 3 D-10): uno sheet può riferirsi al personaggio
/// precedente o a un Cubit chiuso.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authenticatedBuilder,
    required this.legalConsentStore,
  });

  final Widget Function(BuildContext context, User user) authenticatedBuilder;
  final LegalConsentStore legalConsentStore;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          _leavesSession(previous, current) ||
          _changesCharacter(previous, current),
      listener: (context, _) =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: _shouldRebuild,
        builder: (context, state) => switch (state) {
          AuthBootstrapping() => SplashScreen(
            watchConnection: true,
            onManualSignIn: context.read<AuthCubit>().showSignIn,
          ),
          AuthUnauthenticated(:final reason) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => SignInCubit(
                  context.read<AuthTokenService>(),
                  const UrlLauncherLinkOpener(),
                ),
              ),
              BlocProvider(
                create: (_) => _consentFor(reason, legalConsentStore),
              ),
            ],
            child: SignInScreen(notice: _noticeFor(reason)),
          ),
          AuthAuthenticated(:final user) => KeyedSubtree(
            key: ValueKey<String>(user.id),
            child: authenticatedBuilder(context, user),
          ),
        },
      ),
    );
  }

  /// Solo l'account eliminato dimentica il consenso del dispositivo; ogni
  /// altro arrivo al sign-in lo ripristina (Phase 25 D-10).
  static LegalConsentCubit _consentFor(
    UnauthenticatedReason reason,
    LegalConsentStore store,
  ) {
    final cubit = LegalConsentCubit(store, version: LegalDocuments.version);
    return switch (reason) {
      UnauthenticatedReason.accountDeleted => cubit..forget(),
      _ => cubit..restore(),
    };
  }

  static SignInNotice _noticeFor(
    UnauthenticatedReason reason,
  ) => switch (reason) {
    UnauthenticatedReason.signedOut => SignInNotice.none,
    UnauthenticatedReason.sessionExpired => SignInNotice.sessionExpired,
    UnauthenticatedReason.syncLost => SignInNotice.connectionLost,
    UnauthenticatedReason.replacedByNewLogin => SignInNotice.replacedByNewLogin,
    UnauthenticatedReason.roleChanged => SignInNotice.roleChanged,
    UnauthenticatedReason.channelAccessLost => SignInNotice.channelAccessLost,
    UnauthenticatedReason.accountDeleted => SignInNotice.accountDeleted,
  };

  static bool _leavesSession(AuthState previous, AuthState current) =>
      (current is AuthUnauthenticated && previous is! AuthUnauthenticated) ||
      _changesUser(previous, current);

  static bool _changesUser(AuthState previous, AuthState current) =>
      previous is AuthAuthenticated &&
      current is AuthAuthenticated &&
      previous.user.id != current.user.id;

  static bool _changesCharacter(AuthState previous, AuthState current) =>
      previous is AuthAuthenticated &&
      current is AuthAuthenticated &&
      previous.user.currentCharacter?.id != current.user.currentCharacter?.id;

  static bool _shouldRebuild(AuthState previous, AuthState current) =>
      previous.runtimeType != current.runtimeType ||
      _changesUser(previous, current) ||
      _changesCharacter(previous, current) ||
      (previous is AuthUnauthenticated &&
          current is AuthUnauthenticated &&
          previous.reason != current.reason);
}
