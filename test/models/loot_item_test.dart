import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

LootItem _potion({Object? injuries}) => LootItem.fromJson({
  'id': 'l-potion',
  'name': 'Pozione',
  'rarity': 'common',
  'effect': 'heal',
  'power': 12,
  if (injuries != null) 'effectedInjuries': injuries,
});

void main() {
  group('LootItem.effectedInjuries', () {
    test(
      'parses the injuries a heal item can cure as an unmodifiable list',
      () {
        final potion = _potion(injuries: ['deepCut', 'infection']);

        expect(potion.effectedInjuries, [
          InjuryType.deepCut,
          InjuryType.infection,
        ]);
        expect(
          () => potion.effectedInjuries.add(InjuryType.blackEye),
          throwsUnsupportedError,
        );
      },
    );

    test('drops unknown injury names instead of throwing', () {
      expect(_potion(injuries: ['deepCut', 'brokenWing']).effectedInjuries, [
        InjuryType.deepCut,
      ]);
    });

    test('is empty when the wire omits the field or sends a non-list', () {
      expect(_potion().effectedInjuries, isEmpty);
      expect(_potion(injuries: 'deepCut').effectedInjuries, isEmpty);
      expect(_potion(injuries: 3).effectedInjuries, isEmpty);
      expect(
        () => _potion().effectedInjuries.add(InjuryType.blackEye),
        throwsUnsupportedError,
      );
    });

    test('writes the injury names back in toJson', () {
      expect(
        _potion(injuries: ['deepCut', 'infection']).toJson(),
        containsPair('effectedInjuries', ['deepCut', 'infection']),
      );
      expect(_potion().toJson(), containsPair('effectedInjuries', isEmpty));
    });

    test('round-trips through toJson and lists the injuries in props', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(LootItem.fromJson(potion.toJson()), potion);
      expect(_potion(injuries: ['deepCut']), isNot(potion));
      expect(_potion(), isNot(potion));
    });

    test('copyWith keeps the injuries unless they are replaced', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(potion.copyWith(power: 20).effectedInjuries, [
        InjuryType.deepCut,
        InjuryType.infection,
      ]);
      expect(
        potion
            .copyWith(effectedInjuries: [InjuryType.blackEye])
            .effectedInjuries,
        [InjuryType.blackEye],
      );
    });
  });
}
