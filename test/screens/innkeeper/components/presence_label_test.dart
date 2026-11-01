import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/presence_label.dart';

void main() {
  group('presenceLabelOf', () {
    test('a present participant reads «Presente»', () {
      expect(presenceLabelOf(const ParticipantPresent()), 'Presente');
    });

    test('a traveller reads the remaining game time', () {
      expect(
        presenceLabelOf(
          const ParticipantTravelling(remaining: Duration(minutes: 12)),
        ),
        'In viaggio · 12 min',
      );
    });

    test('an unreadable travel reads «In viaggio» without time', () {
      expect(
        presenceLabelOf(const ParticipantTravellingUnknown()),
        'In viaggio',
      );
    });

    test('an arrived traveller reads «Arrivato»', () {
      expect(presenceLabelOf(const ParticipantArrived()), 'Arrivato');
    });

    test('a participant awaiting aid reads «In attesa di soccorso»', () {
      expect(
        presenceLabelOf(const ParticipantAwaitingAid()),
        'In attesa di soccorso',
      );
    });
  });
}
