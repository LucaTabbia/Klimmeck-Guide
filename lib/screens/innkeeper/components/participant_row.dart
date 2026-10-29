import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/presence_label.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga «nome · stato · Teletrasporta» di un partecipante (10-CONTEXT D-08,
/// D-19); chi viaggia è sbiadito (D-06) ma resta teletrasportabile.
class ParticipantRow extends StatelessWidget {
  const ParticipantRow({
    super.key,
    required this.participant,
    required this.serverNow,
    required this.onTeleport,
    required this.isPreparingTeleport,
  });

  static const String teleportLabel = 'Teletrasporta';

  static Key keyFor(String characterId) =>
      ValueKey('innkeeper.participant.$characterId');

  final PendingRequestCharacter participant;
  final DateTime serverNow;

  /// `null` mentre un'altra riga legge il suo personaggio.
  final VoidCallback? onTeleport;

  /// Lettura di `character(id)` in corso per questa riga (D-15/C3).
  final bool isPreparingTeleport;

  static Key teleportKeyFor(String characterId) =>
      ValueKey('innkeeper.teleport.$characterId');

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final presence = presenceOf(participant, serverNow);
    final details = Row(
      children: [
        Expanded(
          child: Text(
            participant.name,
            style: theme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: KlimmeckGuideTheme.spacingSm),
        Flexible(
          flex: 2,
          child: Text(
            presenceLabelOf(presence),
            style: theme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
    return Row(
      children: [
        Expanded(
          child: presence.blocksCompletion
              ? Opacity(
                  opacity: KlimmeckGuideTheme.pendingInkOpacity,
                  child: details,
                )
              : details,
        ),
        const SizedBox(width: KlimmeckGuideTheme.spacingSm),
        _buildTeleportAction(),
      ],
    );
  }

  Widget _buildTeleportAction() {
    if (isPreparingTeleport) {
      return const SizedBox.square(
        dimension: KlimmeckGuideTheme.spacingMd,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return TextButton(
      key: teleportKeyFor(participant.id),
      onPressed: onTeleport,
      child: const Text(teleportLabel),
    );
  }
}
