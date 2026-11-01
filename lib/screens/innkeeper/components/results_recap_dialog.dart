import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riepilogo del GM sul pannello (10-CONTEXT D-13): i giocatori ricevono il proprio foglio sul loro device.
Future<void> showResultsRecap(
  BuildContext context, {
  required RequestCard card,
  required List<QuestResult> results,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final theme = KlimmeckGuideTheme.instance;
    return AlertDialog(
      title: Text('Richiesta completata', style: theme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final result in results) ...[
              const SizedBox(height: KlimmeckGuideTheme.spacingSm),
              Text(recapNameOf(result, card), style: theme.bodyLarge),
              for (final line in resultRecapLinesOf(result))
                Text(line, style: theme.bodyMedium),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  },
);
