import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

SpellOutcome _outcome({
  SpellOperation operation = SpellOperation.equip,
  SpellOutcomeKind kind = SpellOutcomeKind.failed,
  SpellEquipFailure? failure,
}) => SpellOutcome(
  sequence: 1,
  spellId: 'spell-a',
  operation: operation,
  kind: kind,
  failure: failure,
);

void main() {
  group('spellNoticeFor', () {
    test('a slots-full block has the equip title and the slots copy', () {
      expect(
        spellNoticeFor(_outcome(kind: SpellOutcomeKind.blockedSlotsFull)),
        const KGNotification(
          title: 'Magia non equipaggiata',
          description: 'Slot pieni: disequipaggia una magia',
        ),
      );
    });

    test('a no-slots block has the equip title and the no-slots copy', () {
      expect(
        spellNoticeFor(_outcome(kind: SpellOutcomeKind.blockedNoSlots)),
        const KGNotification(
          title: 'Magia non equipaggiata',
          description: 'Nessuno slot disponibile',
        ),
      );
    });

    final descriptions = {
      SpellEquipFailure.notKnown: 'Non conosci questa magia',
      SpellEquipFailure.slotsFull: 'Slot pieni: disequipaggia una magia',
      SpellEquipFailure.notFound: 'Questa magia non è più disponibile',
      SpellEquipFailure.forbidden: 'Questo personaggio non può farlo',
      SpellEquipFailure.badUserInput: 'Qualcosa è andato storto, riprova',
      SpellEquipFailure.connection: 'Connessione assente, riprova',
      SpellEquipFailure.timedOut:
          'Il server non ha risposto in tempo: '
          'controlla le magie prima di riprovare',
      SpellEquipFailure.declined:
          'Il server ha rifiutato la richiesta, riprova',
      SpellEquipFailure.unknown: 'Qualcosa è andato storto, riprova',
    };
    descriptions.forEach((failure, description) {
      test('${failure.name} has the fixed copy for an equip', () {
        expect(
          spellNoticeFor(_outcome(failure: failure)),
          KGNotification(
            title: 'Magia non equipaggiata',
            description: description,
          ),
        );
      });

      test('${failure.name} has the unequip title for an unequip', () {
        expect(
          spellNoticeFor(
            _outcome(operation: SpellOperation.unequip, failure: failure),
          ),
          KGNotification(title: 'Magia non tolta', description: description),
        );
      });
    });

    for (final failure in [
      SpellEquipFailure.alreadyActive,
      SpellEquipFailure.notActive,
      SpellEquipFailure.unauthenticated,
    ]) {
      test('${failure.name} shows no banner', () {
        expect(spellNoticeFor(_outcome(failure: failure)), isNull);
      });
    }

    test('a settle by timeout shows no banner (WR-01)', () {
      expect(
        spellNoticeFor(_outcome(kind: SpellOutcomeKind.settledByTimeout)),
        isNull,
      );
    });

    test('a failed outcome without a failure reads as unknown', () {
      expect(
        spellNoticeFor(_outcome()),
        const KGNotification(
          title: 'Magia non equipaggiata',
          description: 'Qualcosa è andato storto, riprova',
        ),
      );
    });

    test('no copy leaks a technical token', () {
      for (final failure in SpellEquipFailure.values) {
        final description = spellNoticeFor(
          _outcome(failure: failure),
        )?.description;
        if (description == null) continue;
        for (final token in ['SPELL_', 'MAX_', 'Exception', 'null']) {
          expect(description, isNot(contains(token)), reason: failure.name);
        }
      }
    });
  });
}
