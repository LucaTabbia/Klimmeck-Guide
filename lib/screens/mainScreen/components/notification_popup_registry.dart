import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart';

/// Popup di contesto aperto dopo l'atterraggio sul tab Mappa (D-15).
typedef NotificationPopup =
    void Function(BuildContext context, NotificationIntent intent);

/// Un popup per tipo di notifica. Phase 7: `travelEnd` centra solo la camera
/// sulla pedina, nessun foglio né popup (D-15); Phase 9 aggiunge `questEnd`.
const Map<NotificationCategory, NotificationPopup> defaultNotificationPopups = {
  NotificationCategory.travelEnd: focusCharacterOnMap,
};

/// D-15/D-16: vale per il tap sulla notifica di sistema e sul banner in-app.
void focusCharacterOnMap(BuildContext context, NotificationIntent intent) =>
    context.read<MapFocusCubit>().requestCharacterFocus();
