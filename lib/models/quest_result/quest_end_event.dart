import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Copy del push `questEnd` (BE Phase 9 §4) e del banner pubblicato dalla
/// subscription (D-12): un solo posto per le stesse stringhe.
const String questEndTitle = 'Missione conclusa';
const String questEndBody = "La tua missione è terminata: scopri com'è andata.";

/// Evento del banner per un risultato arrivato dalla subscription (D-12): la
/// chiave `questEnd|<id>` coincide con quella del push in foreground (dedup).
PushEvent questEndEventOf(QuestResult result) => PushEvent(
  category: NotificationCategory.questEnd,
  title: questEndTitle,
  body: questEndBody,
  sentAt: result.resolvedAt,
  id: result.id,
);
