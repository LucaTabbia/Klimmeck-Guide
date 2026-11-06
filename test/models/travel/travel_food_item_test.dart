import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_food_item.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  test('parses the item id and name and the quantity (D-01)', () {
    final entry = TravelFoodItem.tryFromJson(
      travelFoodItemJson(
        id: 'loot-ration',
        name: 'Razione da viaggio',
        quantity: 2,
      ),
    )!;

    expect(entry.item.id, 'loot-ration');
    expect(entry.name, 'Razione da viaggio');
    expect(entry.quantity, 2);
  });

  test('listFrom keeps the backend order (D-01)', () {
    final food = TravelFoodItem.listFrom([
      travelFoodItemJson(),
      travelFoodItemJson(id: 'loot-apple', name: 'Mela selvatica'),
    ]);

    expect(food.map((entry) => entry.name), [
      'Razione da viaggio',
      'Mela selvatica',
    ]);
  });

  test(
    'listFrom drops an entry without a named item or with a quantity below 1 (D-01)',
    () {
      final food = TravelFoodItem.listFrom([
        {'quantity': 1},
        {'quantity': 1, 'item': 'x'},
        {
          'quantity': 1,
          'item': {'name': 'Senza id'},
        },
        {
          'quantity': 1,
          'item': {'id': 3, 'name': 'Id numerico'},
        },
        travelFoodItemJson(name: ''),
        travelFoodItemJson(name: null),
        travelFoodItemJson(quantity: 0),
        {
          'quantity': '2',
          'item': {'id': 'loot-ration', 'name': 'Razione da viaggio'},
        },
        'x',
        travelFoodItemJson(id: 'loot-apple', name: 'Mela selvatica'),
      ]);

      expect(food, hasLength(1));
      expect(food.single.name, 'Mela selvatica');
    },
  );

  test('ignores item fields beyond the id and the name (D-01)', () {
    final food = TravelFoodItem.listFrom([
      {
        'quantity': 1,
        'item': {
          'id': 'loot-apple',
          'name': 'Mela selvatica',
          'effect': 'notAnEffect',
          'rarity': 'notARarity',
        },
      },
    ]);

    expect(food.single.item.id, 'loot-apple');
  });

  test('listFrom reads anything but a list as no food (D-01)', () {
    expect(TravelFoodItem.listFrom(null), isEmpty);
    expect(TravelFoodItem.listFrom('x'), isEmpty);
    expect(TravelFoodItem.listFrom(<String, dynamic>{}), isEmpty);
  });

  test('listFrom returns an unmodifiable list (D-01)', () {
    final food = TravelFoodItem.listFrom([travelFoodItemJson()]);

    expect(() => food.add(food.first), throwsUnsupportedError);
  });

  test('toJson round-trips through tryFromJson (D-01)', () {
    final entry = TravelFoodItem.tryFromJson(travelFoodItemJson(quantity: 3))!;

    expect(TravelFoodItem.tryFromJson(entry.toJson()), entry);
  });
}
