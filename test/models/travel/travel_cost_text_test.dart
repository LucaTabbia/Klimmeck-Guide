import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_cost_text.dart';
import 'package:klimmeck_guide/models/travel/travel_food_item.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

TravelPreview _preview({required int hpLost, required bool arrivesAlive}) =>
    TravelPreview.fromJson(
      travelPreviewJson(
        food: [travelFoodItemJson()],
        hpLost: hpLost,
        arrivesAlive: arrivesAlive,
      ),
    );

void main() {
  test('foodText lists the food in backend order as «Nx nome» (D-02)', () {
    final food = TravelFoodItem.listFrom([
      travelFoodItemJson(),
      travelFoodItemJson(id: 'loot-apple', name: 'Mela selvatica', quantity: 2),
    ]);

    expect(
      foodText(food, empty: 'nessuno'),
      '1x Razione da viaggio, 2x Mela selvatica',
    );
  });

  test('foodText reads the given empty text without food (D-02, D-04)', () {
    expect(foodText(const [], empty: 'nessuno'), 'nessuno');
    expect(foodText(const [], empty: 'nessun cibo'), 'nessun cibo');
  });

  test('lifeText prints the life lost with a minus sign (D-02, D-11)', () {
    final text = lifeText(_preview(hpLost: 136, arrivesAlive: true));

    expect(text, '−136 HP');
    expect(text.codeUnitAt(0), 0x2212);
  });

  test('lifeText reads «nessuna perdita» when no life is lost (D-02)', () {
    expect(
      lifeText(_preview(hpLost: 0, arrivesAlive: true)),
      'nessuna perdita',
    );
  });

  test(
    'lifeText reads the user phrase when the character would not arrive alive (D-06, D-10)',
    () {
      final text = lifeText(_preview(hpLost: 20910, arrivesAlive: false));

      expect(text, starvingPhrase);
      expect(text, isNot(contains('HP')));
    },
  );

  test('starvingPhrase is the user phrase verbatim (D-06)', () {
    expect(starvingPhrase, 'Non hai cibo a sufficienza per il viaggio');
  });
}
