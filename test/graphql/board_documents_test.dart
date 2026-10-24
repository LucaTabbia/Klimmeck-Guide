import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('GetCity', () {
    final operation = parseString(
      CityQueries.getCity,
    ).definitions.whereType<OperationDefinitionNode>().single;

    test('is a single query named GetCity with a typed id variable', () {
      expect(operation.type, OperationType.query);
      expect(operation.name?.value, 'GetCity');
      final variable = operation.variableDefinitions.single;
      final type = variable.type as NamedTypeNode;
      expect(variable.variable.name.value, 'id');
      expect(type.name.value, 'String');
      expect(type.isNonNull, isTrue);
    });

    test('selects the city POIs and the marker by id only', () {
      expect(
        _collapsed(CityQueries.getCity),
        contains(
          'city(id: \$id) { id markerLocation { id } pointsOfInterest { id } }',
        ),
      );
    });

    test('is registered in the schema check', () {
      expect(schemaCheckDocuments['GetCity'], CityQueries.getCity);
    });
  });

  group('quests document', () {
    final document = _collapsed(QuestQueries.getAllQuests);

    test('selects the BE Phase 8 rank slots and registrations', () {
      expect(document, contains('registeredAdventurers { character title }'));
      expect(document, contains('requiredAdventurers { title count }'));
      expect(document, contains('recommendedLoot { quantity item {'));
    });

    test('selects the populated enemy and lore references', () {
      expect(document, contains('enemy { id name imagePath }'));
      expect(document, contains('relatedLore { id name description }'));
      // il premio loot viene reso con LootItemCard: servono effect e power
      expect(
        RegExp(
          r'prizeItem \{[\s\S]*?\.\.\. on LootItem \{[^}]*\beffect\b[^}]*\}',
        ).hasMatch(document),
        isTrue,
        reason: 'prizeItem loot must select effect',
      );
      expect(
        RegExp(
          r'prizeItem \{[\s\S]*?\.\.\. on LootItem \{[^}]*\bpower\b[^}]*\}',
        ).hasMatch(document),
        isTrue,
        reason: 'prizeItem loot must select power',
      );
    });

    test('leaves the removed and unsafe fields out', () {
      for (final forbidden in [
        'party',
        'locations',
        'pointsOfInterest',
        'relatedLore { id name description type',
      ]) {
        expect(document, isNot(contains(forbidden)), reason: forbidden);
      }
      expect(
        RegExp(r'registeredAdventurers(?! \{)').hasMatch(document),
        isFalse,
      );
    });

    test('parses to one operation named quests', () {
      final operation = parseString(
        QuestQueries.getAllQuests,
      ).definitions.whereType<OperationDefinitionNode>().single;
      expect(operation.name?.value, 'quests');
    });
  });
}
