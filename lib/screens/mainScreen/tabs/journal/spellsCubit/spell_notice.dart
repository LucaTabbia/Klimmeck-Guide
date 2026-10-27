import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

const String spellEquipNoticeTitle = 'Magia non equipaggiata';
const String spellUnequipNoticeTitle = 'Magia non tolta';
const String _slotsFullLine = 'Slot pieni: disequipaggia una magia';

/// Copy di dominio del banner (D-07, D-11, D-17), provvisoria (no UI phase).
/// Nessun banner per le viste stantie e per una chiusura per timeout
/// (riallineamento silenzioso) né per UNAUTHENTICATED (il flusso di sessione
/// sta già agendo).
KGNotification? spellNoticeFor(SpellOutcome outcome) {
  final description = switch (outcome.kind) {
    SpellOutcomeKind.blockedSlotsFull => _slotsFullLine,
    SpellOutcomeKind.blockedNoSlots => 'Nessuno slot disponibile',
    SpellOutcomeKind.settledByTimeout => null,
    SpellOutcomeKind.failed => _failureLine(
      outcome.failure ?? SpellEquipFailure.unknown,
    ),
  };
  if (description == null) return null;
  return KGNotification(
    title: outcome.operation == SpellOperation.unequip
        ? spellUnequipNoticeTitle
        : spellEquipNoticeTitle,
    description: description,
  );
}

String? _failureLine(SpellEquipFailure failure) => switch (failure) {
  SpellEquipFailure.notKnown => 'Non conosci questa magia',
  SpellEquipFailure.alreadyActive => null,
  SpellEquipFailure.slotsFull => _slotsFullLine,
  SpellEquipFailure.notActive => null,
  SpellEquipFailure.notFound => 'Questa magia non è più disponibile',
  SpellEquipFailure.forbidden => 'Questo personaggio non può farlo',
  SpellEquipFailure.badUserInput => 'Qualcosa è andato storto, riprova',
  SpellEquipFailure.unauthenticated => null,
  SpellEquipFailure.connection => 'Connessione assente, riprova',
  SpellEquipFailure.timedOut =>
    'Il server non ha risposto in tempo: '
        'controlla le magie prima di riprovare',
  SpellEquipFailure.declined => 'Il server ha rifiutato la richiesta, riprova',
  SpellEquipFailure.unknown => 'Qualcosa è andato storto, riprova',
};
