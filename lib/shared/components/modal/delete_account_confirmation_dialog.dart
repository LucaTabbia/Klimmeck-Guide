import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';

/// Conferma l'eliminazione del proprio account (D-01, D-05): elenca ciò che
/// va perduto. Il chiamante legge il Cubit prima dell'await (il dialog vive
/// sul Navigator radice).
Future<bool> showDeleteAccountConfirmation(BuildContext context) =>
    showDestructiveConfirmation(
      context,
      title: "Eliminare l'account?",
      body:
          'Il tuo nome sarà cancellato dai registri della Guida: tutti i tuoi '
          'personaggi, anche quelli archiviati, con progressi, oggetti, magie '
          'e compagni, il saldo dei punti e il ritratto andranno perduti per '
          'sempre. I punti canale già convertiti non verranno restituiti. '
          "L'azione è irreversibile: uscirai subito dall'App.",
      confirmLabel: 'Elimina',
    );
