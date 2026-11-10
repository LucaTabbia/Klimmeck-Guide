import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/pet_fragment.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/shop_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void _expectPetSlotMutation({
  required String document,
  required String operationName,
  required String requestType,
  required String field,
}) {
  final operation = _operationOf(document);
  final variable = operation.variableDefinitions.single;
  final type = variable.type as NamedTypeNode;

  expect(operation.type, OperationType.mutation);
  expect(operation.name?.value, operationName);
  expect(variable.variable.name.value, 'request');
  expect(type.name.value, requestType);
  expect(type.isNonNull, isTrue);
  expect(
    _collapsed(document),
    contains('$field(request: \$request) { response successful }'),
  );
}

void main() {
  final cityShop = _collapsed(ShopQueries.getCityShop);
  final petFields = _collapsed(PetFragment.fields);

  test('GetCityShop is a single query with a non-null ID cityId (D-01)', () {
    final operation = _operationOf(ShopQueries.getCityShop);
    final variable = operation.variableDefinitions.single;
    final type = variable.type as NamedTypeNode;

    expect(operation.type, OperationType.query);
    expect(operation.name?.value, 'GetCityShop');
    expect(variable.variable.name.value, 'cityId');
    expect(type.name.value, 'ID');
    expect(type.isNonNull, isTrue);
  });

  test('GetCityShop selects only the city id, never its name (D-02)', () {
    expect(
      cityShop,
      contains('cityShop(cityId: \$cityId) { city { id } equipment {'),
    );
    expect(cityShop, isNot(contains('city { id name')));
    expect(
      RegExp(r'\bname\b').hasMatch(cityShop.split('equipment {').first),
      isFalse,
    );
  });

  test('GetCityShop selects equipment and loot through the item fragments '
      '(D-01)', () {
    expect(cityShop, contains('... on EquipmentItem'));
    expect(cityShop, contains('... on LootItem'));
  });

  test('GetCityShop equipment selects accessoryUseTypes (D-15)', () {
    expect(cityShop, contains('equipType accessoryUseTypes'));
  });

  test('GetCityShop selects pets through PetFragment without imagePath '
      '(D-13)', () {
    expect(cityShop, contains('pets { $petFields }'));
    expect(cityShop, isNot(contains('imagePath')));
  });

  test('PetFragment selects id, name, speed, sellable and both prices '
      '(D-11)', () {
    expect(
      petFields,
      'id name speedModifier sellable '
      'buyPrice { gold silver copper } sellPrice { gold silver copper }',
    );
  });

  test('cities selects size and hasShop for the satchel gate (D-04)', () {
    expect(
      _collapsed(CityQueries.getAllCities),
      contains('cities { id type name size hasShop markerLocation {'),
    );
  });

  test('EquipPet declares EquipPetRequest! and selects response successful '
      '(D-16)', () {
    _expectPetSlotMutation(
      document: CharacterMutations.equipPet,
      operationName: 'EquipPet',
      requestType: 'EquipPetRequest',
      field: 'equipPet',
    );
  });

  test('UnequipPet declares UnequipPetRequest! and selects response '
      'successful (D-16)', () {
    _expectPetSlotMutation(
      document: CharacterMutations.unequipPet,
      operationName: 'UnequipPet',
      requestType: 'UnequipPetRequest',
      field: 'unequipPet',
    );
  });

  test('the registry lists GetCityShop, EquipPet and UnequipPet', () {
    expect(schemaCheckDocuments['GetCityShop'], ShopQueries.getCityShop);
    expect(schemaCheckDocuments['EquipPet'], CharacterMutations.equipPet);
    expect(schemaCheckDocuments['UnequipPet'], CharacterMutations.unequipPet);
  });

  test('the global catalogue queries left the registry (D-01)', () {
    expect(schemaCheckDocuments, isNot(contains('equipmentAssetsQuantity')));
    expect(schemaCheckDocuments, isNot(contains('lootAssetsQuantity')));
    expect(schemaCheckDocuments.length, 46);
  });
}
