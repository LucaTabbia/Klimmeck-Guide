import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart';

/// Popup di contesto aperto dopo l'atterraggio sul tab Mappa (D-15).
typedef NotificationPopup =
    void Function(BuildContext context, NotificationIntent intent);

/// Un popup per tipo di notifica. `travelEnd` centra solo la camera sulla
/// pedina, nessun foglio né popup (Phase 7 D-15); `questEnd` chiede il
/// risultato alla coda dei risultati (Phase 9 D-06/D-11).
const Map<NotificationCategory, NotificationPopup> defaultNotificationPopups = {
  NotificationCategory.travelEnd: focusCharacterOnMap,
  NotificationCategory.questEnd: requestQuestResult,
};

/// D-15/D-16: vale per il tap sulla notifica di sistema e sul banner in-app.
void focusCharacterOnMap(BuildContext context, NotificationIntent intent) =>
    context.read<MapFocusCubit>().requestCharacterFocus();

/// D-06/D-11: il tap su `questEnd` porta alla mappa (landing) e chiede il
/// risultato alla coda; il foglio si apre quando la mappa è libera.
void requestQuestResult(BuildContext context, NotificationIntent intent) =>
    context.read<QuestResultsCubit>().requestFromTap(intent.id);
