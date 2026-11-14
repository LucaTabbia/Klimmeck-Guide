import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Passo «Luogo» (D-01, D-29): dove si trova ciascuno, il teletrasporto del
/// gruppo sulla Mappa o il salto del passo quando il gruppo è già insieme.
class PlaceStep extends StatelessWidget {
  const PlaceStep({
    super.key,
    required this.draft,
    required this.participants,
    required this.isSubmitting,
    required this.onTeleport,
    required this.onStay,
  });

  static const String teleportLabel = 'Teletrasporta il gruppo';
  static const String stayLabel = 'Resta qui';
  static const Key teleportKey = ValueKey('mission.place.teleport');
  static const Key stayKey = ValueKey('mission.place.stay');

  final MissionDraft draft;
  final MissionParticipantsState participants;
  final bool isSubmitting;
  final VoidCallback onTeleport;
  final ValueChanged<String> onStay;

  @override
  Widget build(BuildContext context) {
    final loaded = switch (participants) {
      final MissionParticipantsLoaded loaded => loaded,
      _ => null,
    };
    final canAct = loaded != null && !isSubmitting;
    final sharedPlaceId = loaded?.commonLocationId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
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
              onPressed: canAct ? onTeleport : null,
              child: const Text(teleportLabel),
            ),
            OutlinedButton(
              key: stayKey,
              onPressed: canAct && sharedPlaceId != null
                  ? () => onStay(sharedPlaceId)
                  : null,
              child: const Text(stayLabel),
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
    return '${participant.name} · ${loaded.placeLabelFor(locationId)}';
  }
}
