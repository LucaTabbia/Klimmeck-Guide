import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/sign_in_screen.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';

/// Guardia di routing state-driven (docs/rules/architecture.md): l'albero
/// dipende solo da [AuthCubit].
///
/// - `AuthBootstrapping` → splash come gate del cold start (D-17/D-18);
/// - `AuthUnauthenticated` → sign-in, con notice se la sessione è scaduta;
/// - `AuthAuthenticated` → [authenticatedBuilder] sotto una chiave legata a
///   `user.id`: logout e cambio account sostituiscono l'intera sessione.
///
/// Quando la sessione finisce (`AuthUnauthenticated`) o cambia utente chiude
/// dialog e sheet aperti sul Navigator radice, che vivono fuori dal
/// sotto-albero della sessione.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authenticatedBuilder});

  final Widget Function(BuildContext context, User user) authenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: _leavesSession,
      listener: (context, _) =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: _shouldRebuild,
        builder: (context, state) => switch (state) {
          AuthBootstrapping() => SplashScreen(
            watchConnection: true,
            onManualSignIn: context.read<AuthCubit>().showSignIn,
          ),
          AuthUnauthenticated(:final reason) => BlocProvider(
            create: (context) => SignInCubit(context.read<AuthTokenService>()),
            child: SignInScreen(
              showSessionExpiredNotice:
                  reason == UnauthenticatedReason.sessionExpired,
            ),
          ),
          AuthAuthenticated(:final user) => KeyedSubtree(
            key: ValueKey<String>(user.id),
            child: authenticatedBuilder(context, user),
          ),
        },
      ),
    );
  }

  static bool _leavesSession(AuthState previous, AuthState current) =>
      (current is AuthUnauthenticated && previous is! AuthUnauthenticated) ||
      _changesUser(previous, current);

  static bool _changesUser(AuthState previous, AuthState current) =>
      previous is AuthAuthenticated &&
      current is AuthAuthenticated &&
      previous.user.id != current.user.id;

  static bool _shouldRebuild(AuthState previous, AuthState current) =>
      previous.runtimeType != current.runtimeType ||
      _changesUser(previous, current) ||
      (previous is AuthUnauthenticated &&
          current is AuthUnauthenticated &&
          previous.reason != current.reason);
}
