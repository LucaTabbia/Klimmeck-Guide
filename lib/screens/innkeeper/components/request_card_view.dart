import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
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
    required this.onTeleport,
    required this.preparingCharacterId,
  });

  static Key keyFor(String cardKey) => ValueKey('innkeeper.card.$cardKey');

  static Key completeKeyFor(String cardKey) =>
      ValueKey('innkeeper.complete.$cardKey');

  static Key teleportKeyFor(String cardKey) =>
      ValueKey('innkeeper.teleport.$cardKey');

  static const String teleportLabel = 'Teletrasporta';

  static const String _fallbackTypeLabel = 'Richiesta';

  final RequestCard card;
  final DateTime serverNow;

  /// Apre il form: unico ingresso al completamento, mai senza conferma (D-11).
  final ValueChanged<RequestCard> onComplete;

  /// Un solo teletrasporto per carta: tutti i partecipanti nello stesso luogo
  /// (D-15, UAT 2026-11-01).
  final ValueChanged<RequestCard> onTeleport;

  /// Il primo partecipante della carta letta per il teletrasporto: blocca le
  /// altre carte.
  final String? preparingCharacterId;

  bool get _isPreparing => preparingCharacterId == card.participants.first.id;

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
            // C6 resta per sicurezza.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildTeleportAction(),
                const SizedBox(width: KlimmeckGuideTheme.spacingSm),
                ElevatedButton(
                  key: completeKeyFor(card.cardKey),
                  style: KlimmeckGuideTheme.primaryButtonStyle,
                  onPressed: card.canComplete(serverNow)
                      ? () => onComplete(card)
                      : null,
                  child: const Text('Completa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeleportAction() {
    if (_isPreparing) {
      return const SizedBox.square(
        dimension: KlimmeckGuideTheme.spacingMd,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return TextButton(
      key: teleportKeyFor(card.cardKey),
      onPressed: preparingCharacterId == null ? () => onTeleport(card) : null,
      child: const Text(teleportLabel),
    );
  }
}
