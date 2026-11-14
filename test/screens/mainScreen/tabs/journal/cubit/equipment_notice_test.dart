import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/equipment_notice.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

KGNotification _notice(String description) =>
    KGNotification(title: equipmentNoticeTitle, description: description);

void main() {
  test('the title is «Equipaggiamento non cambiato» (D-30)', () {
    expect(equipmentNoticeTitle, 'Equipaggiamento non cambiato');
  });

  test('missionInProgress shows the wait line under «Equipaggiamento non '
      'cambiato» (D-30)', () {
    expect(
      equipmentNoticeFor(EquipmentFailure.missionInProgress),
      _notice(missionInProgressRefusalLine),
    );
  });

  test('unauthenticated has no banner', () {
    expect(equipmentNoticeFor(EquipmentFailure.unauthenticated), isNull);
  });

  test('connection says to retry', () {
    expect(
      equipmentNoticeFor(EquipmentFailure.connection),
      _notice('Connessione assente, riprova'),
    );
  });

  test('forbidden says the character cannot do it', () {
    expect(
      equipmentNoticeFor(EquipmentFailure.forbidden),
      _notice('Questo personaggio non può farlo'),
    );
  });

  test('declined says the server refused', () {
    expect(
      equipmentNoticeFor(EquipmentFailure.declined),
      _notice('Il server ha rifiutato la richiesta, riprova'),
    );
  });

  for (final failure in [
    EquipmentFailure.notFound,
    EquipmentFailure.badUserInput,
    EquipmentFailure.timedOut,
    EquipmentFailure.unknown,
  ]) {
    test('${failure.name} gets the generic retry line', () {
      expect(
        equipmentNoticeFor(failure),
        _notice('Qualcosa è andato storto, riprova'),
      );
    });
  }
}
