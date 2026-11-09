import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest_travel_line.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

TravelPreview _preview({
  List<Map<String, dynamic>> food = const [],
  int hpLost = 0,
  bool arrivesAlive = true,
}) => TravelPreview.fromJson(
  travelPreviewJson(food: food, hpLost: hpLost, arrivesAlive: arrivesAlive),
);

void main() {
  test('is null without a preview (D-04)', () {
    expect(QuestTravelLine.of(null), isNull);
  });

  test('reads the food and «nessuna perdita» on a covered trip (D-04)', () {
    final line = QuestTravelLine.of(_preview(food: [travelFoodItemJson()]));

    expect(line?.text, 'Viaggio: 1x Razione da viaggio · nessuna perdita');
    expect(line?.isStarving, isFalse);
  });

  test(
    'reads «nessun cibo» and the life lost on an uncovered trip (D-04, D-11)',
    () {
      final line = QuestTravelLine.of(_preview(hpLost: 136));

      expect(line?.text, 'Viaggio: nessun cibo · −136 HP');
      expect(line?.isStarving, isFalse);
    },
  );

  test('lists several foods in backend order (D-04)', () {
    final line = QuestTravelLine.of(
      _preview(
        food: [
          travelFoodItemJson(),
          travelFoodItemJson(
            id: 'loot-apple',
            name: 'Mela selvatica',
            quantity: 2,
          ),
        ],
        hpLost: 12,
      ),
    );

    expect(
      line?.text,
      'Viaggio: 1x Razione da viaggio, 2x Mela selvatica · −12 HP',
    );
  });

  test(
    'reads the user phrase and is starving when the character would not arrive alive (D-04, D-06)',
    () {
      final line = QuestTravelLine.of(
        _preview(
          food: [travelFoodItemJson()],
          hpLost: 20910,
          arrivesAlive: false,
        ),
      );

      expect(line?.text, 'Viaggio: Non hai cibo a sufficienza per il viaggio');
      expect(line?.isStarving, isTrue);
    },
  );

  test(
    'the line keeps the Phase 15 text and never mentions an ambush (D-07, D-17)',
    () {
      final covered = QuestTravelLine.of(
        TravelPreview.fromJson(
          travelPreviewJson(
            food: [travelFoodItemJson()],
            hpLost: 0,
            arrivesAlive: true,
          ),
        ),
      )!;
      final starving = QuestTravelLine.of(
        TravelPreview.fromJson(
          travelPreviewJson(
            food: [travelFoodItemJson()],
            hpLost: 0,
            arrivesAlive: false,
          ),
        ),
      )!;

      expect(covered.text, 'Viaggio: 1x Razione da viaggio · nessuna perdita');
      expect(
        starving.text,
        'Viaggio: Non hai cibo a sufficienza per il viaggio',
      );
      expect(covered.text, isNot(contains('Imbosc')));
      expect(starving.text, isNot(contains('Imbosc')));
    },
  );
}
