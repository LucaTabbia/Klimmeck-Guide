import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferencesAsync in memoria. Campi tutti `final` perché la classe
/// reale è `@immutable` (must_be_immutable): i fallimenti si accodano in liste.
class FakeSharedPreferencesAsync extends Fake
    implements SharedPreferencesAsync {
  FakeSharedPreferencesAsync([Map<String, Object>? initial])
    : values = {...?initial};

  final Map<String, Object> values;
  final List<Object> readFailures = [];
  final List<Object> writeFailures = [];

  @override
  Future<bool?> getBool(String key) async {
    if (readFailures.isNotEmpty) throw readFailures.removeAt(0);
    return values[key] as bool?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    if (writeFailures.isNotEmpty) throw writeFailures.removeAt(0);
    values[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    if (readFailures.isNotEmpty) throw readFailures.removeAt(0);
    return values[key] as String?;
  }

  @override
  Future<void> setString(String key, String value) async {
    if (writeFailures.isNotEmpty) throw writeFailures.removeAt(0);
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (writeFailures.isNotEmpty) throw writeFailures.removeAt(0);
    values.remove(key);
  }
}
