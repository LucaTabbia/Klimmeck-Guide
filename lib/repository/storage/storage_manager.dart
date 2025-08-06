import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';

class KGStorageManager {
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

  static Future<Character?> getCharacter() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/testCharacter.json');
      return Character.fromJson(jsonDecode(jsonString));
        } catch (e) {
      print('Errore nel parsing del personaggio: $e');
      return null;
    }
  }

  static Future<List<City>?> getCities() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/testCities.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => City.fromJson(json)).toList();
        } catch (e) {
      print('Errore nel parsing delle città: $e');
      return null;
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
}
