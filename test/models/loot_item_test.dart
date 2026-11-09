import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

LootItem _potion({Object? injuries}) => LootItem.fromJson({
  'id': 'l-potion',
  'name': 'Pozione',
  'rarity': 'common',
  'effect': 'heal',
  'power': 12,
  if (injuries != null) 'canHeal': injuries,
});

void main() {
  group('LootItem.canHeal', () {
    test(
      'parses the injuries a heal item can cure as an unmodifiable list',
      () {
        final potion = _potion(injuries: ['deepCut', 'infection']);

        expect(potion.canHeal, [InjuryType.deepCut, InjuryType.infection]);
        expect(
          () => potion.canHeal.add(InjuryType.blackEye),
          throwsUnsupportedError,
        );
      },
    );

    test('drops unknown injury names instead of throwing', () {
      expect(_potion(injuries: ['deepCut', 'brokenWing']).canHeal, [
        InjuryType.deepCut,
      ]);
    });

    test('is empty when the wire omits the field or sends a non-list', () {
      expect(_potion().canHeal, isEmpty);
      expect(_potion(injuries: 'deepCut').canHeal, isEmpty);
      expect(_potion(injuries: 3).canHeal, isEmpty);
      expect(
        () => _potion().canHeal.add(InjuryType.blackEye),
        throwsUnsupportedError,
      );
    });

    test('writes the injury names back in toJson', () {
      expect(
        _potion(injuries: ['deepCut', 'infection']).toJson(),
        containsPair('canHeal', ['deepCut', 'infection']),
      );
      expect(_potion().toJson(), containsPair('canHeal', isEmpty));
    });

    test('round-trips through toJson and lists the injuries in props', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(LootItem.fromJson(potion.toJson()), potion);
      expect(_potion(injuries: ['deepCut']), isNot(potion));
      expect(_potion(), isNot(potion));
    });

    test('copyWith keeps the injuries unless they are replaced', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(potion.copyWith(power: 20).canHeal, [
        InjuryType.deepCut,
        InjuryType.infection,
      ]);
      expect(potion.copyWith(canHeal: [InjuryType.blackEye]).canHeal, [
        InjuryType.blackEye,
      ]);
    });
  });
}
