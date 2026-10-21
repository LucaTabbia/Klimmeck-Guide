import 'package:flutter/widgets.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';

/// Popup di contesto aperto dopo l'atterraggio sul tab Mappa (D-15).
typedef NotificationPopup =
    void Function(BuildContext context, NotificationIntent intent);

/// Un popup per tipo di notifica. Vuoto in Phase 5 (nessun popup, decisione
/// utente): Phase 7 aggiunge `travelEnd`, Phase 9 `questEnd` (esito e morte) —
/// una voce ciascuna.
const Map<NotificationCategory, NotificationPopup> defaultNotificationPopups =
    {};
