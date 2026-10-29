import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/presence_label.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga «nome · stato» di un partecipante (10-CONTEXT D-08); chi viaggia è
/// sbiadito (D-06).
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
    final row = Row(
      children: [
        Text(participant.name, style: theme.bodyLarge),
        const Spacer(),
        Text(presenceLabelOf(presence), style: theme.bodyMedium),
      ],
    );
    if (!presence.blocksCompletion) return row;
    return Opacity(opacity: KlimmeckGuideTheme.pendingInkOpacity, child: row);
  }
}
