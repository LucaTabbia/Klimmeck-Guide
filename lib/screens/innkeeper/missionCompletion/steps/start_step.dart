import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Nessuna bozza servita: la crea solo il tocco dell'oste, che da quel momento
/// blocca i partecipanti (D-11, D-28).
class StartStep extends StatelessWidget {
  const StartStep({super.key, required this.isStarting, required this.onStart});

  static const double _loaderHeight = 48;

  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MissionCompletionScreen.startNote,
              style: KlimmeckGuideTheme.instance.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KlimmeckGuideTheme.spacingMd),
            ElevatedButton(
              key: MissionCompletionScreen.startKey,
              style: KlimmeckGuideTheme.primaryButtonStyle,
              onPressed: isStarting ? null : onStart,
              child: const Text(MissionCompletionScreen.startLabel),
            ),
            if (isStarting) const KGLoader(height: _loaderHeight),
          ],
        ),
      ),
    );
  }
}
