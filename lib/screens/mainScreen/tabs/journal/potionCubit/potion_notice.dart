import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

const String potionNoticeTitle = 'Pozione non bevuta';
const String companionPotionNoticeTitle = 'Pozione non data';
const String _genericLine = 'Qualcosa è andato storto, riprova';

/// Copy del banner di una pozione rifiutata (D-11, D-18), provvisoria.
/// [remaining] è il tempo che manca secondo la data del SERVER: senza, una
/// ricarica in corso ha l'avviso generico (mai una stima locale, D-19).
/// [targetName] è il nome mostrato del compagno bersaglio (D-20, D-32):
/// senza, la pozione era del personaggio e i rifiuti del compagno sono
/// l'avviso generico.
/// Nessun banner per UNAUTHENTICATED: il flusso di sessione sta già agendo.
KGNotification? potionNoticeFor(
  ItemUseFailure failure, {
  Duration? remaining,
  String? targetName,
}) {
  final description = switch (failure) {
    ItemUseFailure.unauthenticated => null,
    ItemUseFailure.potionRecovering => _recoveringLine(
      "Il tuo corpo non reggerebbe un'altra pozione",
      remaining,
    ),
    ItemUseFailure.petDefeated =>
      targetName == null
          ? _genericLine
          : '$targetName è sconfitto: solo il riposo lo rimette in forze',
    ItemUseFailure.petPotionRecovering =>
      targetName == null
          ? _genericLine
          : _recoveringLine(
              "$targetName non reggerebbe un'altra pozione",
              remaining,
            ),
    ItemUseFailure.noEffect =>
      targetName == null
          ? 'Questa pozione non ti farebbe nulla adesso'
          : 'Questa pozione non farebbe nulla a $targetName adesso',
    ItemUseFailure.missionInProgress => missionInProgressRefusalLine,
    ItemUseFailure.awaitingAid ||
    ItemUseFailure.notOwned ||
    ItemUseFailure.notUsable ||
    ItemUseFailure.badUserInput ||
    ItemUseFailure.connection ||
    ItemUseFailure.timedOut ||
    ItemUseFailure.unknown => _genericLine,
  };
  if (description == null) return null;
  return KGNotification(
    title: targetName == null ? potionNoticeTitle : companionPotionNoticeTitle,
    description: description,
  );
}

String _recoveringLine(String refusal, Duration? remaining) {
  if (remaining == null || remaining <= Duration.zero) return _genericLine;
  return '$refusal: ${potionReadyInLine(remaining)}';
}
