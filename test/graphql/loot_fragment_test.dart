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

    test('the recommended and random loot keep the simple fields', () {
      expect(RegExp(r'\bcanHeal\b').allMatches(fields), hasLength(1));
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

    test('the quests query parses as one operation', () {
      expect(
        parseString(
          QuestQueries.getAllQuests,
        ).definitions.whereType<OperationDefinitionNode>(),
        hasLength(1),
      );
    });

    test('the registry stays at 45 documents', () {
      expect(schemaCheckDocuments.length, 45);
    });
  });
}
