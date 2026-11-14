import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Passo «Luogo» (D-01, D-29): dove si trova ciascuno, il teletrasporto del
/// gruppo sulla Mappa o il salto del passo quando il gruppo è già insieme.
/// Il teletrasporto chiede solo i partecipanti della bozza: una lettura
/// fallita non lo blocca mai (D-31).
class PlaceStep extends StatelessWidget {
  const PlaceStep({
    super.key,
    required this.draft,
    required this.participants,
    required this.isSubmitting,
    required this.onTeleport,
    required this.onStay,
    required this.onRetry,
  });

  static const String teleportLabel = 'Teletrasporta il gruppo';
  static const String stayLabel = 'Resta qui';
  static const Key teleportKey = ValueKey('mission.place.teleport');
  static const Key stayKey = ValueKey('mission.place.stay');
  static const Key retryKey = ValueKey('mission.place.retry');

  final MissionDraft draft;
  final MissionParticipantsState participants;
  final bool isSubmitting;
  final VoidCallback onTeleport;
  final ValueChanged<String> onStay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loaded = switch (participants) {
      final MissionParticipantsLoaded loaded => loaded,
      _ => null,
    };
    final sharedPlaceId = loaded?.commonLocationId;
    final failure = switch (participants) {
      MissionParticipantsFailed(:final failure) => failure,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (failure != null)
                Text(
                  MissionCompletionScreen.failureLineOf(failure),
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              for (final participant in draft.participants)
                Text(
                  _rowOf(participant, loaded),
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
            ],
          ),
        ),
        Wrap(
          spacing: KlimmeckGuideTheme.spacingSm,
          children: [
            ElevatedButton(
              key: teleportKey,
              style: KlimmeckGuideTheme.primaryButtonStyle,
              onPressed: isSubmitting ? null : onTeleport,
              child: const Text(teleportLabel),
            ),
            OutlinedButton(
              key: stayKey,
              onPressed: !isSubmitting && sharedPlaceId != null
                  ? () => onStay(sharedPlaceId)
                  : null,
              child: const Text(stayLabel),
            ),
            if (failure != null)
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

  static String _rowOf(
    MissionParticipant participant,
    MissionParticipantsLoaded? loaded,
  ) {
    if (loaded == null) return participant.name;
    final locationId =
        loaded.characters[participant.characterId]?.status?.location?.id;
    final placeLabel = loaded.placeLabelFor(locationId);
    if (placeLabel.isEmpty) return participant.name;
    return '${participant.name} · $placeLabel';
  }
}
