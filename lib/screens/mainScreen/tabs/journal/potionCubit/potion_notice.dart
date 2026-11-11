import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

const String potionNoticeTitle = 'Pozione non bevuta';
const String _genericLine = 'Qualcosa è andato storto, riprova';

/// Copy del banner di una pozione rifiutata (D-11, D-18), provvisoria.
/// [remaining] è il tempo che manca secondo la data del SERVER: senza, una
/// ricarica in corso ha l'avviso generico (mai una stima locale, D-19).
/// Nessun banner per UNAUTHENTICATED: il flusso di sessione sta già agendo.
KGNotification? potionNoticeFor(ItemUseFailure failure, {Duration? remaining}) {
  final description = switch (failure) {
    ItemUseFailure.unauthenticated => null,
    ItemUseFailure.potionRecovering => _recoveringLine(remaining),
    ItemUseFailure.noEffect => 'Questa pozione non ti farebbe nulla adesso',
    ItemUseFailure.awaitingAid ||
    ItemUseFailure.notOwned ||
    ItemUseFailure.notUsable ||
    ItemUseFailure.badUserInput ||
    ItemUseFailure.connection ||
    ItemUseFailure.timedOut ||
    ItemUseFailure.unknown => _genericLine,
  };
  if (description == null) return null;
  return KGNotification(title: potionNoticeTitle, description: description);
}

String _recoveringLine(Duration? remaining) {
  if (remaining == null || remaining <= Duration.zero) return _genericLine;
  return "Il tuo corpo non reggerebbe un'altra pozione: "
      '${potionReadyInLine(remaining)}';
}
