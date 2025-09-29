import 'package:shared_preferences/shared_preferences.dart';

class KGStorageManager {
  static const String cachedUrls = "cachedUrls";

  static Future<void> saveCachedUrls(List<String> urls) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(cachedUrls, urls);
  }

  static Future<List<String>?> getCachedUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(cachedUrls);
  }
}
