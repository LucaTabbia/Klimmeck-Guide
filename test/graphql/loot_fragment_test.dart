import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/queries/loot_item_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';
import 'package:klimmeck_guide/graphql/queries/shop_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Documenti che selezionano i LootItem completi (negozio, Diario, loot).
final Map<String, String> _fullLootDocuments = {
  'getCityShop': ShopQueries.getCityShop,
  'getCharacter': CharacterQueries.getCharacter,
  'characterUpdated': CharacterSubscriptions.characterUpdated,
  'getAllLootItems': LootItemQueries.getAllLootItems,
  'getLootItemsByIds': LootItemQueries.getLootItemsByIds,
};

void main() {
  group('LootFragment', () {
    test('fields select canHeal after power', () {
      expect(
        _collapsed(LootFragment.fields),
        contains('effect power canHeal buyPrice {'),
      );
    });

    test('definition selects canHeal after power', () {
      expect(
        _collapsed(LootFragment.definition),
        contains('effect power canHeal buyPrice {'),
      );
    });

    test('simpleFields stay without canHeal', () {
      expect(LootFragment.simpleFields, isNot(contains('canHeal')));
    });

    test(
      'fields and definition select recovery { time turns } (D-13, D-19)',
      () {
        for (final selection in [
          LootFragment.fields,
          LootFragment.definition,
        ]) {
          expect(
            _collapsed(selection),
            contains(
              'sellPrice { gold silver copper } recovery { time turns }',
            ),
          );
        }
      },
    );

    test('simpleFields stay without recovery (D-19)', () {
      expect(LootFragment.simpleFields, isNot(contains('recovery')));
    });

    test('no fragment selects the related lore of an item (D-16)', () {
      for (final selection in [
        LootFragment.fields,
        LootFragment.definition,
        LootFragment.simpleFields,
      ]) {
        expect(selection, isNot(contains('relatedLore')));
      }
    });
  });

  group('QuestFragment', () {
    final fields = _collapsed(QuestFragment.fields);

    test('the prize item loot block selects canHeal', () {
      expect(
        fields,
        contains(
          '... on LootItem { ${_collapsed(LootFragment.simpleFields)} '
          'description effect power canHeal }',
        ),
      );
    });

    test('the recommended and random loot keep the simple fields '
        'and the cure (D-01)', () {
      expect(RegExp(r'\bcanHeal\b').allMatches(fields), hasLength(2));
    });
  });

  group('documents', () {
    for (final entry in _fullLootDocuments.entries) {
      test('${entry.key} selects canHeal and parses as one operation', () {
        expect(entry.value, contains('canHeal'));
        expect(
          parseString(
            entry.value,
          ).definitions.whereType<OperationDefinitionNode>(),
          hasLength(1),
        );
      });
    }

    for (final entry in _fullLootDocuments.entries) {
      test('the full loot documents select recovery (D-13): ${entry.key}', () {
        expect(_collapsed(entry.value), contains('recovery { time turns }'));
      });
    }

    test('the quests query parses as one operation', () {
      expect(
        parseString(
          QuestQueries.getAllQuests,
        ).definitions.whereType<OperationDefinitionNode>(),
        hasLength(1),
      );
    });

    test('the registry stays at 54 documents (D-17, D-25, D-29)', () {
      expect(schemaCheckDocuments.length, 54);
    });
  });
}
