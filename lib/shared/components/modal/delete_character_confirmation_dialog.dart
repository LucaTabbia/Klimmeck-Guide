import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';

/// Conferma l'eliminazione del personaggio corrente (D-15). Il chiamante
/// legge il Cubit prima dell'await (il dialog vive sul Navigator radice).
Future<bool> showDeleteCharacterConfirmation(
  BuildContext context, {
  String? characterName,
}) => showDestructiveConfirmation(
  context,
  title: 'Eliminare il personaggio?',
  body:
      "Sei sicuro di voler eliminare ${characterName ?? 'il tuo personaggio'}? "
      "L'azione è irreversibile.",
  confirmLabel: 'Elimina',
);
