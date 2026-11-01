import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/presence_label.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga «nome · stato» di un partecipante (10-CONTEXT D-08); il teletrasporto
/// è della carta intera (UAT 2026-11-01) e una carta elencata non ha viaggiatori.
class ParticipantRow extends StatelessWidget {
  const ParticipantRow({
    super.key,
    required this.participant,
    required this.serverNow,
  });

  static Key keyFor(String characterId) =>
      ValueKey('innkeeper.participant.$characterId');

  final PendingRequestCharacter participant;
  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final presence = presenceOf(participant, serverNow);
    return Row(
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
  }
}
