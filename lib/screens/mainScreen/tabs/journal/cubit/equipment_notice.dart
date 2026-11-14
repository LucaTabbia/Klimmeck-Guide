import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

const String equipmentNoticeTitle = 'Equipaggiamento non cambiato';
const String _genericLine = 'Qualcosa è andato storto, riprova';

/// Copy del banner di un cambio di equipaggiamento rifiutato (D-30).
/// Nessun banner per UNAUTHENTICATED: il flusso di sessione sta già agendo.
KGNotification? equipmentNoticeFor(EquipmentFailure failure) {
  final description = switch (failure) {
    EquipmentFailure.unauthenticated => null,
    EquipmentFailure.missionInProgress => missionInProgressRefusalLine,
    EquipmentFailure.forbidden => 'Questo personaggio non può farlo',
    EquipmentFailure.connection => 'Connessione assente, riprova',
    EquipmentFailure.declined => 'Il server ha rifiutato la richiesta, riprova',
    EquipmentFailure.notFound ||
    EquipmentFailure.badUserInput ||
    EquipmentFailure.timedOut ||
    EquipmentFailure.unknown => _genericLine,
  };
  if (description == null) return null;
  return KGNotification(title: equipmentNoticeTitle, description: description);
}
