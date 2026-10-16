import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Dialog di conferma per azioni distruttive (utility surface, D-07/D-15).
/// Vive sul Navigator radice: restituisce solo un bool, non legge Cubit.
class DestructiveConfirmationDialog extends StatelessWidget {
  const DestructiveConfirmationDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return AlertDialog(
      title: Text(title, style: theme.titleMedium),
      content: Text(body, style: theme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annulla',
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.deepNight,
            ),
          ),
        ),
        ElevatedButton(
          style: KlimmeckGuideTheme.destructiveButtonStyle,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.parchment,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> showDestructiveConfirmation(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DestructiveConfirmationDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
      ),
    ) ??
    false;
