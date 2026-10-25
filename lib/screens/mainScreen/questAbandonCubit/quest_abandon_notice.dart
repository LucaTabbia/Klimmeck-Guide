import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';

const String questAbandonNoticeTitle = 'Abbandono non riuscito';

/// Copy di dominio provvisoria (nessuna UI phase). Nessun avviso per
/// FORBIDDEN/UNAUTHENTICATED: li gestisce il flusso di sessione.
KGNotification? questAbandonNoticeFor(QuestAbandonFailure failure) {
  final description = switch (failure) {
    QuestAbandonFailure.notWaiting =>
      'La missione è già cominciata: non puoi più abbandonarla',
    QuestAbandonFailure.notFound => 'Non sei più in questa missione',
    QuestAbandonFailure.connection ||
    QuestAbandonFailure.timedOut ||
    QuestAbandonFailure.unknown => 'Impossibile abbandonare ora, riprova',
    QuestAbandonFailure.forbidden ||
    QuestAbandonFailure.unauthenticated => null,
  };
  if (description == null) return null;
  return KGNotification(
    title: questAbandonNoticeTitle,
    description: description,
  );
}
