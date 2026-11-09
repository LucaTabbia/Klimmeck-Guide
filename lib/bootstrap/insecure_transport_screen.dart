import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

const String insecureTransportMessage =
    'Questa versione dell\'app non può collegarsi al server in modo sicuro. Installa una versione aggiornata.';

/// Utility screen (chrome ammesso solo qui, CLAUDE.md regola 1): build release
/// con URL in chiaro (D-03b). Nessun pulsante: l'unico rimedio è una build
/// corretta.
class InsecureTransportScreen extends StatelessWidget {
  const InsecureTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KlimmeckGuideTheme.instance.materialTheme,
      color: KlimmeckGuideTheme.deepNight,
      home: Scaffold(
        body: DecoratedBox(
          decoration: KlimmeckGuideTheme.getBackgroundDecoration(),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
                child: Text(
                  insecureTransportMessage,
                  textAlign: TextAlign.center,
                  style: KlimmeckGuideTheme.instance.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
