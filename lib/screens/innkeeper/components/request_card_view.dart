import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Una carta della coda (10-CONTEXT D-05/D-08): titolo, tipo, posti per una
/// worldMission e le righe dei partecipanti, tutti presenti (UAT 2026-11-01).
class RequestCardView extends StatelessWidget {
  const RequestCardView({
    super.key,
    required this.card,
    required this.serverNow,
    required this.onComplete,
  });

  static Key keyFor(String cardKey) => ValueKey('innkeeper.card.$cardKey');

  static Key completeKeyFor(String cardKey) =>
      ValueKey('innkeeper.complete.$cardKey');

  static const String completeLabel = 'Completa';

  /// Bozza del flusso guidato già avviata (21-CONTEXT D-17).
  static const String resumeLabel = 'Riprendi';

  static const String _fallbackTypeLabel = 'Richiesta';

  final RequestCard card;
  final DateTime serverNow;

  /// Apre il form: unico ingresso al completamento, mai senza conferma (D-11).
  final ValueChanged<RequestCard> onComplete;

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
            const SizedBox(height: KlimmeckGuideTheme.spacingSm),
            // La coda elenca solo carte azionabili (UAT 2026-11-01): la guardia
            // C6 resta per sicurezza. Il teletrasporto è il primo passo del
            // wizard, non un'azione della carta (UAT 2026-11-14).
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: completeKeyFor(card.cardKey),
                style: KlimmeckGuideTheme.primaryButtonStyle,
                onPressed: card.canComplete(serverNow)
                    ? () => onComplete(card)
                    : null,
                child: Text(card.hasMissionDraft ? resumeLabel : completeLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
