import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import 'cubit/splash_cubit.dart';

const String _connectionHintText =
    'Connessione instabile, attendere o accedere manualmente';
const String _manualSignInLabel = 'Accedi manualmente';
const String _signAsset = 'assets/images/splashSign.png';
const double _signTopPadding = 16;
const double _signToTextGap = 16;

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
    return BackgroundImage(
      child: SafeArea(
        minimum: const EdgeInsets.only(top: _signTopPadding, bottom: 48),
        child: Center(
          child: Column(
            children: [
              Expanded(child: Image.asset(_signAsset, fit: BoxFit.contain)),
              const SizedBox(height: _signToTextGap),
              BlocBuilder<SplashCubit, SplashState>(
                builder: (context, state) => switch (state) {
                  SplashNetworkDelayed() when widget.watchConnection =>
                    _ConnectionHint(onManualSignIn: widget.onManualSignIn),
                  SplashPreloading(:final percent) => _PreloadProgress(
                    percent: percent,
                  ),
                  _ => const _AnimatedLoadingText(),
                },
              ),
            ],
          ),
        ),
      ),
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

/// Scritta di caricamento con, sotto, la percentuale delle immagini scaricate.
class _PreloadProgress extends StatelessWidget {
  const _PreloadProgress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AnimatedLoadingText(),
          Text(
            '$percent%',
            style: KlimmeckGuideTheme.instance.lightText.copyWith(
              color: KlimmeckGuideTheme.parchment,
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
  /// I punti non ancora accesi occupano comunque il loro posto, trasparenti:
  /// la scritta non si sposta mentre si aggiungono.
  static const int _maxDots = 3;

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
              _dotCount = (_dotCount % _maxDots) + 1;
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
    return Material(
      type: MaterialType.transparency,
      child: Text.rich(
        TextSpan(
          text: 'Caricamento',
          children: [
            TextSpan(text: '.' * _dotCount),
            TextSpan(
              text: '.' * (_maxDots - _dotCount),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
        style: KlimmeckGuideTheme.instance.specialText.copyWith(
          color: KlimmeckGuideTheme.parchment,
        ),
      ),
    );
  }
}
