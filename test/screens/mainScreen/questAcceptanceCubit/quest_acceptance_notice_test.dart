import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
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
