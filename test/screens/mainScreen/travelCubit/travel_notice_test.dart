import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_notice.dart';

void main() {
  group('travelNoticeFor', () {
    final descriptions = {
      TravelFailure.inProgress: 'Sei già in viaggio',
      TravelFailure.sameLocation: 'Sei già in questa città',
      TravelFailure.destinationNotAllowed:
          'Puoi viaggiare solo verso una città',
      TravelFailure.noPath: 'Nessuna strada porta a questa meta',
      TravelFailure.questInProgress:
          'Non puoi partire durante una missione in corso',
      TravelFailure.awaitingAid: 'Sei in attesa di soccorso: non puoi partire',
      TravelFailure.notFound: 'Questa meta non è più raggiungibile',
      TravelFailure.forbidden: 'Questo personaggio non può partire',
      TravelFailure.connection: 'Connessione assente, riprova',
      TravelFailure.timedOut:
          'Il server non ha risposto in tempo: '
          'controlla la mappa prima di riprovare',
      TravelFailure.declined: 'Il server ha rifiutato la partenza, riprova',
      TravelFailure.unknown: 'Qualcosa è andato storto, riprova',
    };
    descriptions.forEach((failure, description) {
      test('${failure.name} has the fixed copy', () {
        expect(
          travelNoticeFor(failure),
          KGNotification(
            title: 'Viaggio non partito',
            description: description,
          ),
        );
      });
    });

    test('unauthenticated shows no banner', () {
      expect(travelNoticeFor(TravelFailure.unauthenticated), isNull);
    });

    test('no copy leaks a technical token', () {
      for (final failure in TravelFailure.values) {
        final description = travelNoticeFor(failure)?.description;
        if (description == null) continue;
        for (final token in ['TRAVEL_', 'QUEST_', 'Exception', 'null']) {
          expect(description, isNot(contains(token)), reason: failure.name);
        }
      }
    });
  });
}
