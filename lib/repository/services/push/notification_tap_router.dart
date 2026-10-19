import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/link_opener.dart';
import 'package:klimmeck_guide/repository/services/push/notification_intent_sink.dart';

/// Unica azione per ogni tap (notifica di sistema o banner, D-15/D-16/D-17): i
/// tipi personali atterrano sul tab Mappa via [NotificationIntentSink];
/// `streamerLive` apre il canale Twitch. L'unico URL mai aperto è la costante di
/// [TwitchChannel], mai un valore del payload.
class NotificationTapRouter {
  NotificationTapRouter({
    required NotificationIntentSink intents,
    required LinkOpener links,
  }) : _intents = intents,
       _links = links;

  final NotificationIntentSink _intents;
  final LinkOpener _links;

  Future<void> handle(NotificationIntent intent) async {
    if (intent.category.isPersonal) {
      _intents.offer(intent);
      return;
    }
    if (!await _links.open(TwitchChannel.uri)) {
      debugPrint('Twitch channel not opened');
    }
  }
}
