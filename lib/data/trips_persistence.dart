import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';
import 'trips_json.dart';

/// Локальное хранение списка поездок.
abstract final class TripsPersistence {
  static const _key = 'build_trip_trips_v1';

  /// `null` — в хранилище ещё не сохраняли поездки (первый запуск).
  /// Список (в т.ч. пустой) — данные прочитаны; при битом JSON возвращаем
  /// пустой список, чтобы не перезаписывать файл моковыми данными.
  static Future<List<Trip>?> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }
    if (raw.isEmpty) {
      return [];
    }
    try {
      return TripsJson.decodeList(raw);
    } on Object {
      return [];
    }
  }

  static Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, TripsJson.encodeList(trips));
  }
}
