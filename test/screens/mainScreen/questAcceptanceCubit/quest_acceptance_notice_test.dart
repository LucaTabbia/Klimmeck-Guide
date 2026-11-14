import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart';

void main() {
  group('questAcceptanceNoticeFor', () {
    final descriptions = {
      QuestAcceptanceFailure.full: 'Non ci sono più posti per il tuo rango',
      QuestAcceptanceFailure.alreadyTaken: 'Hai già affrontato questa missione',
      QuestAcceptanceFailure.titleMismatch:
          'Il tuo titolo non permette questa missione',
      QuestAcceptanceFailure.notInCity:
          'Devi trovarti nella città della missione',
      QuestAcceptanceFailure.notAcceptable:
          'Missione non disponibile, avvisa il locandiere',
      QuestAcceptanceFailure.insufficientPoints: 'Punti canale insufficienti',
      QuestAcceptanceFailure.notFound:
          'Questa missione non è più sulla bacheca',
      QuestAcceptanceFailure.forbidden:
          'Questo personaggio non può accettare la missione',
      QuestAcceptanceFailure.travelInProgress:
          "Sei in viaggio: riprova all'arrivo",
      QuestAcceptanceFailure.awaitingAid:
          'Sei in attesa di soccorso: non puoi accettare missioni',
      QuestAcceptanceFailure.starving:
          'Non hai cibo a sufficienza per il viaggio',
      QuestAcceptanceFailure.connection: 'Connessione assente, riprova',
      QuestAcceptanceFailure.timedOut:
          'Il server non ha risposto in tempo: '
          'controlla la bacheca prima di riprovare',
      QuestAcceptanceFailure.unknown: 'Qualcosa è andato storto, riprova',
    };
    descriptions.forEach((failure, description) {
      test('${failure.name} has the fixed copy', () {
        final notice = questAcceptanceNoticeFor(failure)!;

        expect(notice.title, 'Missione non accettata');
        expect(notice.description, description);
      });
    });

    test('starving explains the missing food with the user phrase (D-06)', () {
      expect(
        questAcceptanceNoticeFor(QuestAcceptanceFailure.starving),
        const KGNotification(
          title: 'Missione non accettata',
          description: 'Non hai cibo a sufficienza per il viaggio',
        ),
      );
    });

    test('slotBusy depends on the quest type', () {
      String of(QuestType? type) => questAcceptanceNoticeFor(
        QuestAcceptanceFailure.slotBusy,
        type: type,
      )!.description;

      expect(of(QuestType.story), 'Hai già una storia in corso');
      expect(
        of(QuestType.worldMission),
        'Hai già una missione mondiale in corso',
      );
      expect(of(QuestType.hunt), 'Hai già una missione in corso');
      expect(of(null), 'Hai già una missione in corso');
    });

    test('a no-effect refusal says the temple can do nothing (D-20)', () {
      expect(
        questAcceptanceNoticeFor(
          QuestAcceptanceFailure.noEffect,
          type: QuestType.heal,
        ),
        const KGNotification(
          title: 'Missione non accettata',
          description: 'Il tempio non può fare nulla per te adesso',
        ),
      );
    });

    test('BAD_USER_INPUT shows the generic copy (D-13)', () {
      expect(
        questAcceptanceNoticeFor(
          QuestAcceptanceFailure.badUserInput,
          type: QuestType.hunt,
        )!.description,
        'Qualcosa è andato storto, riprova',
      );
    });

    test('imprisoned shows the release time from the server date '
        '(quick 261110-cgd)', () {
      expect(
        questAcceptanceNoticeFor(
          QuestAcceptanceFailure.imprisoned,
          imprisonedFor: const Duration(minutes: 42),
        )!.description,
        'Sei in prigione: uscirai fra 42 min',
      );
      expect(
        questAcceptanceNoticeFor(
          QuestAcceptanceFailure.imprisoned,
        )!.description,
        'Sei in prigione',
      );
    });

    test('missionInProgress shows the wait line for every quest type '
        '(D-13, D-30)', () {
      for (final type in [
        QuestType.story,
        QuestType.worldMission,
        QuestType.hunt,
        null,
      ]) {
        expect(
          questAcceptanceNoticeFor(
            QuestAcceptanceFailure.missionInProgress,
            type: type,
          ),
          const KGNotification(
            title: 'Missione non accettata',
            description: "Sei impegnato in una missione: aspetta l'esito",
          ),
          reason: '$type',
        );
      }
    });

    test('unauthenticated has no banner', () {
      expect(
        questAcceptanceNoticeFor(QuestAcceptanceFailure.unauthenticated),
        isNull,
      );
    });

    test('no description leaks technical words', () {
      for (final failure in QuestAcceptanceFailure.values) {
        final description = questAcceptanceNoticeFor(failure)?.description;
        if (description == null) continue;

        expect(description, isNot(contains('Exception')));
        expect(description, isNot(contains('Error')));
        expect(description, isNot(contains('code')));
      }
    });
  });
}
