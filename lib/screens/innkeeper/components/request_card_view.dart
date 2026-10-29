import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Una carta per quest della coda (10-CONTEXT D-05/D-08): titolo, tipo, posti
/// per una worldMission e le righe dei partecipanti visibili.
class RequestCardView extends StatelessWidget {
  const RequestCardView({
    super.key,
    required this.card,
    required this.serverNow,
  });

  static Key keyFor(String questId) => ValueKey('innkeeper.card.$questId');

  static const String _fallbackTypeLabel = 'Richiesta';
  static const String busyParticipantNote =
      'Un partecipante è impegnato in una missione';

  final RequestCard card;
  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: KlimmeckGuideTheme.darkBronze),
        borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(card.questTitle, style: theme.titleMedium),
            Text(
              card.questType?.label ?? _fallbackTypeLabel,
              style: theme.bodyMedium,
            ),
            if (card.showsSeats)
              Text(
                '${card.entryCount}/${card.totalSeats} posti',
                style: theme.bodyMedium,
              ),
            const SizedBox(height: KlimmeckGuideTheme.spacingSm),
            for (final participant in card.participants)
              ParticipantRow(
                key: ParticipantRow.keyFor(participant.id),
                participant: participant,
                serverNow: serverNow,
              ),
            // default per veto (10-CONTEXT D-07): il partecipante impegnato
            // resta nascosto e la carta lo dice.
            if (card.hasHiddenParticipants) ...[
              const SizedBox(height: KlimmeckGuideTheme.spacingSm),
              Text(
                '${card.participants.length} presenti su ${card.entryCount} registrati',
                style: theme.bodyMedium,
              ),
              Text(busyParticipantNote, style: theme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
