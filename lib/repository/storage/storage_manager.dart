import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:graphql/client.dart';
import 'package:klimmeck_guide/graphql/quest_queries.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../graphql/character_queries.dart';
import '../../graphql/city_queries.dart';
import '../../models/equipment_item.dart';
import '../../models/lore.dart';
import '../../models/user.dart';

class KGStorageManager {
  static bool useMockData = true; // toggle JSON / GraphQL

  // GraphQL client
  static final GraphQLClient client = GraphQLClient(link: HttpLink('test'), cache: GraphQLCache());
  static const String firebaseTokenKey = "token_firebase";
  static const String userTokenKey = "user_token";
  static const String loggedUser = "user";
  static const String login = "login";
  static const String showOnBoarding = "show_on_boarding";

  static void savePrimitivePreference(String key, Object value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is List<String>) {
      prefs.setStringList(key, value);
    }
  }

  static Future<User?> getLoggedUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString(loggedUser);
    if (jsonString != null) {
      return User.fromJson(jsonDecode(jsonString));
    } else {
      return null;
    }
  }

  static Future<void> saveLoggedUser(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(loggedUser, jsonEncode(user));
  }

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userTokenKey, token);
  }

  static Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userTokenKey) ?? '';
  }

  static Future<void> saveFirebaseToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(firebaseTokenKey, token);
  }

  static Future<String?> getFirebaseToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(firebaseTokenKey);
  }

  static Future<bool?> getShowOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(showOnBoarding);
  }

  static Future<void> saveShowOnBoarding(bool show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(showOnBoarding, show);
  }

  static Future<bool> checkUserLogged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(login) ?? false;
  }

  static Future<void> saveUserLoggedCheck(bool isLogged) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(login, isLogged);
  }

  static Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (String key in prefs.getKeys()) {
      if (key != showOnBoarding) {
        prefs.remove(key);
      }
    }
  }

  static Future<Character?> getCharacterLocal() async {
    final jsonString = await rootBundle.loadString('assets/testCharacter.json');
    return Character.fromJson(jsonDecode(jsonString));
  }

  static Future<List<City>?> getAllCitiesLocal() async {
    final jsonString = await rootBundle.loadString('assets/testCities.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((json) => City.fromJson(json)).toList();
  }

  static Future<List<Quest>?> getAllQuestsLocal() async {
    final jsonString = await rootBundle.loadString('assets/testQuests.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((x) => Quest.fromJson(x)).toList();
  }

  static Future<Lore?> getLoreById(String id) async {
    try {
      final jsonString = await rootBundle.loadString('assets/testLore.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final loreJson = jsonList.firstWhere((json) => json['id'] == id, orElse: () => null);

      if (loreJson != null) {
        return Lore.fromJson(loreJson);
      } else {
        return null;
      }
    } catch (e) {
      print('Errore nel parsing di Lore: $e');
      return null;
    }
  }

  static Future<List<EquipmentItem>?> getEquipmentItems(List<String> ids) async {
    try {
      final jsonString = await rootBundle.loadString('assets/testEquipments.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final equipmentList = jsonList.map((x) => EquipmentItem.fromJson(x)).toList();
      return equipmentList.where((equipItem) {
        return ids.contains(equipItem.id);
      }).toList();
    } catch (e) {
      print('Errore nel parsing di Lore: $e');
      return null;
    }
  }

  static Future<List<Lore>?> getLoreByType(LoreType loreType) async {
    try {
      final jsonString = await rootBundle.loadString('assets/testLore.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final loreList = jsonList.map((x) => Lore.fromJson(x)).toList();

      return loreList.where((lore) {
        return loreType == lore.type && lore.unlocked == true;
      }).toList();
    } catch (e) {
      print('Errore nel parsing di Lore: $e');
      return null;
    }
  }

  static Future<List<Lore>?> getLoreByTypes(List<LoreType> loreTypes) async {
    try {
      final jsonString = await rootBundle.loadString('assets/testLore.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loreList = jsonList.map((x) => Lore.fromJson(x)).toList();
      return loreList.where((lore) {
        return loreTypes.contains(lore.type) && lore.unlocked == true;
      }).toList();
    } catch (e) {
      print('Errore nel parsing di Lore: $e');
      return null;
    }
  }

  static Future<Character?> getCharacterRemote() async {
    final result = await client.query(QueryOptions(document: gql(CharacterQueries.getCharacter)));

    if (result.hasException) {
      print('GraphQL Error: ${result.exception}');
      return null;
    }

    final data = result.data?['character'];
    return data != null ? Character.fromJson(data) : null;
  }

  static Future<List<City>?> getAllCitiesRemote() async {
    final result = await client.query(QueryOptions(document: gql(CityQueries.getAllCities)));

    if (result.hasException) {
      print('GraphQL Error: ${result.exception}');
      return null;
    }

    final data = result.data?['allCities'] as List<dynamic>?;
    return data?.map((json) => City.fromJson(json)).toList();
  }

  static Future<List<Quest>?> getAllQuestsRemote() async {
    final result = await client.query(QueryOptions(document: gql(QuestQueries.getAllQuests)));

    if (result.hasException) {
      print('GraphQL Error: ${result.exception}');
      return null;
    }

    final data = result.data?['allQuests'] as List<dynamic>?;
    return data?.map((json) => Quest.fromJson(json)).toList();
  }

  static Future<Character?> getCharacter() async =>
      useMockData ? getCharacterLocal() : getCharacterRemote();

  static Future<List<City>?> getAllCities() async =>
      useMockData ? getAllCitiesLocal() : getAllCitiesRemote();

  static Future<List<Quest>?> getAllQuests() async =>
      useMockData ? getAllQuestsLocal() : getAllQuestsRemote();
}
