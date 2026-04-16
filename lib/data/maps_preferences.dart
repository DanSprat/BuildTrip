import 'package:map_launcher/map_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранение карты по умолчанию для кнопки «Открыть в картах».
abstract final class MapsPreferences {
  static const _key = 'build_trip_preferred_map_type_v1';

  static Future<MapType?> loadPreferredMapType() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    for (final type in MapType.values) {
      if (type.name == raw) {
        return type;
      }
    }
    return null;
  }

  static Future<void> savePreferredMapType(MapType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.name);
  }

  static Future<void> clearPreferredMapType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
