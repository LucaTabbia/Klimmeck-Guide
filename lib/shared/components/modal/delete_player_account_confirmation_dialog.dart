import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';

/// Conferma dell'oste prima di eliminare l'account di un giocatore (D-15):
/// nomina l'utente Twitch digitato, così un errore di battitura si vede.
Future<bool> showDeletePlayerAccountConfirmation(
  BuildContext context, {
  required String twitchLogin,
}) => showDestructiveConfirmation(
  context,
  title: "Eliminare l'account di $twitchLogin?",
  body:
      'Tutti i personaggi di $twitchLogin, anche quelli archiviati, il saldo '
      'dei punti e il ritratto andranno perduti per sempre. '
      "L'azione è irreversibile.",
  confirmLabel: 'Elimina',
);
