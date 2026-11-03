import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';

const String companionEquipNoticeTitle = 'Compagno non equipaggiato';
const String companionUnequipNoticeTitle = 'Compagno non rimosso';

/// Copy del banner (D-06), provvisoria (D-13). Nessun banner per le viste
/// stantie, per una chiusura per timeout né per UNAUTHENTICATED.
KGNotification? companionNoticeFor(CompanionOutcome outcome) {
  if (outcome.kind == CompanionOutcomeKind.settledByTimeout) return null;
  final description = _failureLine(outcome.failure ?? PetEquipFailure.unknown);
  if (description == null) return null;
  return KGNotification(
    title: outcome.operation == CompanionOperation.unequip
        ? companionUnequipNoticeTitle
        : companionEquipNoticeTitle,
    description: description,
  );
}

String? _failureLine(PetEquipFailure failure) => switch (failure) {
  PetEquipFailure.notOwned => null,
  PetEquipFailure.notFound => null,
  PetEquipFailure.forbidden => 'Questo personaggio non può farlo',
  PetEquipFailure.badUserInput => 'Qualcosa è andato storto, riprova',
  PetEquipFailure.unauthenticated => null,
  PetEquipFailure.connection => 'Connessione assente, riprova',
  PetEquipFailure.timedOut =>
    'Il server non ha risposto in tempo: '
        'controlla il compagno prima di riprovare',
  PetEquipFailure.declined => 'Il server ha rifiutato la richiesta, riprova',
  PetEquipFailure.unknown => 'Qualcosa è andato storto, riprova',
};
