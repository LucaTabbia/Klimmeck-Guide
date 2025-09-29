import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/graphql/character_queries.dart';
import 'package:klimmeck_guide/graphql/equipment_item_queries.dart';
import 'package:klimmeck_guide/graphql/loot_item_queries.dart';
import 'package:klimmeck_guide/graphql/lore_queries.dart';
import 'package:klimmeck_guide/graphql/quest_queries.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

import '../../../graphql/city_queries.dart';
import '../../../main.dart';
import '../../../models/lore.dart';
import '../../../models/quest/quest.dart';
import '../../storage/storage_manager.dart';

class KlimmeckGraphQl {
  KlimmeckGraphQl();

  final KGStorageManager localStorage = KGStorageManager();

  String getGenericErrorMessage(OperationException? exception) {
    if (exception != null) {
      if (exception.linkException != null) {
        return 'Network error: ${exception.linkException}';
      }
      if (exception.graphqlErrors.isNotEmpty) {
        final String graphqlError = exception.graphqlErrors.map((e) => e.message).join(', ');
        return 'Server error: $graphqlError';
      }
    }
    return 'Generic server error';
  }

  Future<QueryResult> performQuery(String query, {Map<String, dynamic>? variables}) async {
    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.noCache,
    );
    final client = GraphQLProvider.of(navigatorKey.currentContext!).value;
    final result = await client.query(options);
    return result;
  }

  Future<QueryResult> performMutation({
    required String query,
    Map<String, dynamic> variables = const {},
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(query),
      variables: variables,
      fetchPolicy: FetchPolicy.noCache,
    );
    final client = GraphQLProvider.of(navigatorKey.currentContext!).value;
    final result = await client.mutate(options);
    return result;
  }

  Future<List<City>> getCities() async {
    final result = await performQuery(CityQueries.getAllCities);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? citiesData = result.data?['cities'];
    if (citiesData == null) {
      throw Exception('No cities found');
    }

    return citiesData.map((json) => City.fromJson(json)).toList();
  }

  Future<List<Quest>> getQuests() async {
    final result = await performQuery(QuestQueries.getAllQuests);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? questsData = result.data?['quests'];
    if (questsData == null) {
      throw Exception('No quest found');
    }

    return questsData.map((json) => Quest.fromJson(json)).toList();
  }

  Future<List<EquipmentItem>> getEquipmentItems(List<String> ids) async {
    final result = await performQuery(
      EquipmentItemQueries.getEquipmentItemsByIds,
      variables: {"ids": ids},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? equipmentItemsData = result.data?['equipmentItemsByIds'];
    if (equipmentItemsData == null) {
      throw Exception('No equipmentItems found');
    }

    return equipmentItemsData.map((json) => EquipmentItem.fromJson(json)).toList();
  }

  Future<List<EquipmentItem>> getAllEquipmentItems() async {
    final result = await performQuery(EquipmentItemQueries.getAllEquipmentItems);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? equipmentItemsData = result.data?['equipmentItems'];
    if (equipmentItemsData == null) {
      throw Exception('No quest found');
    }

    return equipmentItemsData.map((json) => EquipmentItem.fromJson(json)).toList();
  }

  Future<List<LootItem>> getLootItems(List<String> ids) async {
    final result = await performQuery(LootItemQueries.getLootItemsByIds, variables: {"ids": ids});
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? lootItemsData = result.data?['lootItemsByIds'];
    if (lootItemsData == null) {
      throw Exception('No quest found');
    }

    return lootItemsData.map((json) => LootItem.fromJson(json)).toList();
  }

  Future<List<LootItem>> getAllLootItems() async {
    final result = await performQuery(LootItemQueries.getAllLootItems);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? lootItemsData = result.data?['lootItems'];
    if (lootItemsData == null) {
      throw Exception('No quest found');
    }

    return lootItemsData.map((json) => LootItem.fromJson(json)).toList();
  }

  Future<Character> getCharacter(String id) async {
    final result = await performQuery(CharacterQueries.getCharacter, variables: {"id": id});
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic characterData = result.data?['character'];
    if (characterData == null) {
      throw Exception('No character found');
    }

    return Character.fromJson(characterData);
  }

  Future<Equipment> getEquipment(String id) async {
    final result = await performQuery(CharacterQueries.getEquipment, variables: {"id": id});
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic equipmentData = result.data?['equipment'];
    if (equipmentData == null) {
      throw Exception('No quest found');
    }

    return Equipment.fromJson(equipmentData);
  }

  Future<List<Lore>> getAllLores() async {
    final result = await performQuery(LoreQueries.getAllLores);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? loresData = result.data?['lores'];
    if (loresData == null) {
      throw Exception('No cities found');
    }

    return loresData.map((json) => Lore.fromJson(json)).toList();
  }

  Future<Lore> getLoreById(String id) async {
    final result = await performQuery(LoreQueries.getLoreById, variables: {"id": id});
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic loreData = result.data?['lore'];
    if (loreData == null) {
      throw Exception('No cities found');
    }

    return Lore.fromJson(loreData);
  }
}
