import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pagina «Storie» (D-01..D-03): una tendina chiusa per partecipante, da
/// leggere prima di decidere. Una lettura fallita non blocca mai il fondo
/// della pagina (D-31).
class StoriesStep extends StatelessWidget {
  const StoriesStep({
    super.key,
    required this.readers,
    required this.participants,
    required this.onRetry,
    required this.footer,
  });

  static const Key retryKey = ValueKey('mission.stories.retry');

  final List<StoryReader> readers;

  /// Le storie per id del personaggio, o la lettura fallita.
  final MissionParticipantsState participants;
  final VoidCallback onRetry;

  /// [StoriesStartFooter] prima della bozza, [StoriesNextFooter] dopo.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final loaded = switch (participants) {
      final MissionParticipantsLoaded loaded => loaded,
      _ => null,
    };
    final failureLine = switch (participants) {
      MissionParticipantsFailed(:final failure) =>
        MissionCompletionScreen.failureLineOf(failure),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (failureLine != null)
                  Text(
                    failureLine,
                    style: KlimmeckGuideTheme.instance.bodyMedium,
                  ),
                for (final reader in readers)
                  ParticipantStory(
                    reader: reader,
                    entries: loaded?.backgroundOf(reader.characterId),
                    pendingLine: failureLine ?? ParticipantStory.readingLine,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: footer),
            if (failureLine != null)
              TextButton(
                key: retryKey,
                onPressed: onRetry,
                child: const Text(MissionCompletionScreen.retryLabel),
              ),
          ],
        ),
      ],
    );
  }
}

/// Fondo della pagina senza bozza: la crea solo il tocco dell'oste, che da
/// quel momento blocca i partecipanti (D-02, D-28).
class StoriesStartFooter extends StatelessWidget {
  const StoriesStartFooter({
    super.key,
    required this.isStarting,
    required this.onStart,
  });

  static const double _loaderSize = 48;

  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          MissionCompletionScreen.startNote,
          style: KlimmeckGuideTheme.instance.bodyMedium,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        Wrap(
          spacing: KlimmeckGuideTheme.spacingSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              key: MissionCompletionScreen.startKey,
              style: KlimmeckGuideTheme.primaryButtonStyle,
              onPressed: isStarting ? null : onStart,
              child: const Text(MissionCompletionScreen.startLabel),
            ),
            if (isStarting)
              const KGLoader(width: _loaderSize, height: _loaderSize),
          ],
        ),
      ],
    );
  }
}

/// Fondo della pagina a missione iniziata: è la prima, «Indietro» è spento e
/// «Avanti» torna a «Luogo» senza salvare (D-02).
class StoriesNextFooter extends StatelessWidget {
  const StoriesNextFooter({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KlimmeckGuideTheme.spacingSm,
      children: [
        const MissionBackButton(),
        ElevatedButton(
          key: MissionCompletionScreen.nextKey,
          style: KlimmeckGuideTheme.primaryButtonStyle,
          onPressed: onNext,
          child: const Text(MissionCompletionScreen.nextLabel),
        ),
      ],
    );
  }
}
