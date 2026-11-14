import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart';

CompanionOutcome _outcome({
  CompanionOperation operation = CompanionOperation.equip,
  CompanionOutcomeKind kind = CompanionOutcomeKind.failed,
  PetEquipFailure? failure,
}) => CompanionOutcome(
  sequence: 1,
  petId: 'pet-horse',
  operation: operation,
  kind: kind,
  failure: failure,
);

void main() {
  group('companionNoticeFor', () {
    test('an equip refusal titles «Compagno non equipaggiato» (D-06)', () {
      expect(
        companionNoticeFor(_outcome(failure: PetEquipFailure.forbidden)),
        const KGNotification(
          title: 'Compagno non equipaggiato',
          description: 'Questo personaggio non può farlo',
        ),
      );
    });

    test('an unequip refusal titles «Compagno non rimosso» (D-06)', () {
      expect(
        companionNoticeFor(
          _outcome(
            operation: CompanionOperation.unequip,
            failure: PetEquipFailure.connection,
          ),
        ),
        const KGNotification(
          title: 'Compagno non rimosso',
          description: 'Connessione assente, riprova',
        ),
      );
    });

    test('stale views show no banner: PET_NOT_OWNED and NOT_FOUND (D-06)', () {
      expect(
        companionNoticeFor(_outcome(failure: PetEquipFailure.notOwned)),
        isNull,
      );
      expect(
        companionNoticeFor(_outcome(failure: PetEquipFailure.notFound)),
        isNull,
      );
    });

    test('UNAUTHENTICATED and a settle by timeout show no banner', () {
      expect(
        companionNoticeFor(_outcome(failure: PetEquipFailure.unauthenticated)),
        isNull,
      );
      expect(
        companionNoticeFor(
          _outcome(kind: CompanionOutcomeKind.settledByTimeout),
        ),
        isNull,
      );
    });

    test('connection, forbidden, timedOut, declined, badUserInput and '
        'unknown have a line', () {
      const lines = {
        PetEquipFailure.connection: 'Connessione assente, riprova',
        PetEquipFailure.forbidden: 'Questo personaggio non può farlo',
        PetEquipFailure.timedOut:
            'Il server non ha risposto in tempo: '
            'controlla il compagno prima di riprovare',
        PetEquipFailure.declined:
            'Il server ha rifiutato la richiesta, riprova',
        PetEquipFailure.badUserInput: 'Qualcosa è andato storto, riprova',
        PetEquipFailure.unknown: 'Qualcosa è andato storto, riprova',
      };
      lines.forEach((failure, line) {
        expect(
          companionNoticeFor(_outcome(failure: failure)),
          KGNotification(title: 'Compagno non equipaggiato', description: line),
          reason: failure.name,
        );
      });
    });

    test('a companion refused during a mission shows the wait line '
        '(D-11, D-30)', () {
      expect(
        companionNoticeFor(
          _outcome(failure: PetEquipFailure.missionInProgress),
        ),
        const KGNotification(
          title: 'Compagno non equipaggiato',
          description: "Sei impegnato in una missione: aspetta l'esito",
        ),
      );
      expect(
        companionNoticeFor(
          _outcome(
            operation: CompanionOperation.unequip,
            failure: PetEquipFailure.missionInProgress,
          ),
        ),
        const KGNotification(
          title: 'Compagno non rimosso',
          description: "Sei impegnato in una missione: aspetta l'esito",
        ),
      );
    });
  });
}
