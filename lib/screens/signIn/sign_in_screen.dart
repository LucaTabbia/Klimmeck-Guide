import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

const String _loginLabel = 'Login con Twitch';
const String _tagline = 'Accedi con Twitch per iniziare la tua avventura.';
const String _sessionExpiredNotice = 'La sessione è scaduta, accedi di nuovo.';
const String _connectionError = 'Errore di connessione, riprova';
const String _twitchUnavailableError =
    'Login con Twitch non ancora disponibile.';
const String _termsLabel = 'Termini di servizio';
const String _privacyLabel = 'Privacy';
const String _logoAsset = 'assets/icons/appIcon/appIcon.png';
const String _twitchGlyphAsset = 'assets/icons/twitch_glitch.svg';

/// Utility screen (chrome ammesso): unico entry point del login.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.showSessionExpiredNotice = false});

  final bool showSessionExpiredNotice;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: DecoratedBox(
        decoration: KlimmeckGuideTheme.getBackgroundDecoration(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      _logoAsset,
                      height: 96,
                      semanticLabel: 'Guida di Klimmeck',
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge.copyWith(
                        color: KlimmeckGuideTheme.parchment,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (showSessionExpiredNotice) ...[
                      Text(
                        _sessionExpiredNotice,
                        textAlign: TextAlign.center,
                        style: theme.errorText.copyWith(
                          color: KlimmeckGuideTheme.parchment,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    BlocBuilder<SignInCubit, SignInState>(
                      builder: (context, state) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TwitchLoginButton(
                            isLoading: state is SignInInProgress,
                            onPressed: () =>
                                context.read<SignInCubit>().signInWithTwitch(),
                          ),
                          const SizedBox(height: 16),
                          _FailureMessage(state: state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _LegalFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwitchLoginButton extends StatelessWidget {
  const _TwitchLoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(KlimmeckGuideTheme.radius);
    return Semantics(
      button: true,
      label: _loginLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  KlimmeckGuideTheme.primaryGold,
                  KlimmeckGuideTheme.darkBronze,
                ],
              ),
              borderRadius: borderRadius,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: isLoading
                      ? const _ButtonSpinner()
                      : const _ButtonLabel(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        color: KlimmeckGuideTheme.deepNight,
        strokeWidth: 2,
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          _twitchGlyphAsset,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            KlimmeckGuideTheme.parchment,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _loginLabel,
          style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
            color: KlimmeckGuideTheme.deepNight,
          ),
        ),
      ],
    );
  }
}

class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.state});

  final SignInState state;

  @override
  Widget build(BuildContext context) {
    final errorStyle = KlimmeckGuideTheme.instance.errorText;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (state) {
        SignInFailed(failure: SignInFailure.twitchNotConfigured) => Text(
          _twitchUnavailableError,
          key: const ValueKey(SignInFailure.twitchNotConfigured),
          textAlign: TextAlign.center,
          style: errorStyle,
        ),
        SignInFailed() => Text(
          _connectionError,
          key: const ValueKey(SignInFailure.connection),
          textAlign: TextAlign.center,
          style: errorStyle,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final style = KlimmeckGuideTheme.instance.lightText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: Text(_termsLabel, style: style),
        ),
        TextButton(
          onPressed: () {},
          child: Text(_privacyLabel, style: style),
        ),
      ],
    );
  }
}
