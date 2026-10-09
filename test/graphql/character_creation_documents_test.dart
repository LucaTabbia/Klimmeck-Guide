import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/auth_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/auth_queries.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';

DocumentNode parse(String document) => parseString(document);

OperationDefinitionNode operationOf(String document) =>
    parse(document).definitions.whereType<OperationDefinitionNode>().single;

int userFieldsDefinitions(String document) => parse(document).definitions
    .whereType<FragmentDefinitionNode>()
    .where((fragment) => fragment.name.value == 'UserFields')
    .length;

void main() {
  group('CreateCharacter', () {
    final document = CharacterMutations.createCharacter;

    test('is a single named operation with the required input variable', () {
      final operation = operationOf(document);

      expect(operation.name?.value, 'CreateCharacter');
      expect(operation.variableDefinitions, hasLength(1));
      final variable = operation.variableDefinitions.single;
      expect(variable.variable.name.value, 'input');
      final type = variable.type as NamedTypeNode;
      expect(type.name.value, 'CreateCharacterInput');
      expect(type.isNonNull, isTrue);
    });

    test('selects the shared UserFields fragment defined exactly once', () {
      expect(document, contains('...UserFields'));
      expect(userFieldsDefinitions(document), 1);
    });
  });

  group('GetRaceTraits', () {
    test('selects race, minAge and maxAge from raceTraits', () {
      final operation = operationOf(CharacterQueries.getRaceTraits);

      expect(operation.name?.value, 'GetRaceTraits');
      final field = operation.selectionSet.selections.single as FieldNode;
      expect(field.name.value, 'raceTraits');
      final selected = field.selectionSet!.selections
          .whereType<FieldNode>()
          .map((f) => f.name.value);
      expect(selected, ['race', 'minAge', 'maxAge']);
    });
  });

  group('documents sharing the user selection', () {
    final documents = {
      'GetMe': AuthQueries.getMe,
      'ExchangeLoginTicket': AuthMutations.exchangeLoginTicket,
      'RefreshSession': AuthMutations.refreshSession,
    };

    documents.forEach((name, document) {
      test('$name parses and defines UserFields exactly once', () {
        expect(operationOf(document).name?.value, name);
        expect(userFieldsDefinitions(document), 1);
      });
    });
  });
}
