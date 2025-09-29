import 'package:shared_preferences/shared_preferences.dart';

class CacheExpiry {
  static const _expiryKey = "svg_cache_expiry";

  static Future<void> setExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryDate = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch;
    await prefs.setInt(_expiryKey, expiryDate);
  }

  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(_expiryKey);
    if (expiry == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < expiry;
  }

  static Future<void> clearExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiryKey);
  }
}
