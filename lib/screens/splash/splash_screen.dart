import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import 'cubit/splash_cubit.dart';

const String _connectionHintText =
    'Connessione instabile, attendere o accedere manualmente';
const String _manualSignInLabel = 'Accedi manualmente';

/// Schermata immersiva (nessun chrome) del cold start e del preload della shell.
///
/// Con [watchConnection] fa da gate del cold start (D-17/D-18): dopo
/// [SplashCubit.connectionHintDelay] mostra l'hint di rete e [onManualSignIn],
/// mentre il bootstrap prosegue in background. La navigazione è di `AuthGate`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.watchConnection = false,
    this.onManualSignIn,
  });

  final bool watchConnection;
  final VoidCallback? onManualSignIn;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();
    _splashCubit = context.read<SplashCubit>();
    if (widget.watchConnection) _splashCubit.startBootstrapWatch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/worldMap.png'), context);
  }

  @override
  void dispose() {
    if (widget.watchConnection) _splashCubit.stopBootstrapWatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Image.asset('assets/images/splash.png', fit: BoxFit.fitWidth),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: BlocBuilder<SplashCubit, SplashState>(
            builder: (context, state) =>
                widget.watchConnection && state is SplashNetworkDelayed
                ? _ConnectionHint(onManualSignIn: widget.onManualSignIn)
                : const _AnimatedLoadingText(),
          ),
        ),
      ],
    );
  }
}

class _ConnectionHint extends StatelessWidget {
  const _ConnectionHint({required this.onManualSignIn});

  final VoidCallback? onManualSignIn;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _connectionHintText,
            textAlign: TextAlign.center,
            style: KlimmeckGuideTheme.instance.specialText.copyWith(
              color: KlimmeckGuideTheme.parchment,
            ),
          ),
          TextButton(
            onPressed: onManualSignIn,
            child: Text(
              _manualSignInLabel,
              style: KlimmeckGuideTheme.instance.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  const _AnimatedLoadingText();

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _dotCount = (_dotCount % 3) + 1;
            });
            _controller.forward(from: 0);
          }
        });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;

    return Material(
      type: MaterialType.transparency,
      child: Text(
        "Caricamento$dots",
        style: KlimmeckGuideTheme.instance.specialText.copyWith(
          color: KlimmeckGuideTheme.parchment,
        ),
      ),
    );
  }
}
