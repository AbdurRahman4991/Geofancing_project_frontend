
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMarketVisitService {
  static const String _key = 'pending_market_visits';

  /// Save Offline Market Visit
  static Future<void> save({
    required double latitude,
    required double longitude,
    String? deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final pending = getPendingFromJson(
      prefs.getString(_key),
    );

    pending.add({
      'latitude': latitude,
      'longitude': longitude,
      'device_id': deviceId,
      'created_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(
      _key,
      jsonEncode(pending),
    );
  }

  /// Get Pending Visits
  static Future<List<Map<String, dynamic>>> getPending() async {
    final prefs = await SharedPreferences.getInstance();

    return getPendingFromJson(
      prefs.getString(_key),
    );
  }

  /// Remove First Successfully Synced Visit
  static Future<void> removeFirst() async {
    final prefs = await SharedPreferences.getInstance();

    final pending = getPendingFromJson(
      prefs.getString(_key),
    );

    if (pending.isNotEmpty) {
      pending.removeAt(0);
    }

    await prefs.setString(
      _key,
      jsonEncode(pending),
    );
  }

  /// Pending Count
  static Future<int> pendingCount() async {
    final pending = await getPending();
    return pending.length;
  }

  /// Clear All Pending Visits
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static List<Map<String, dynamic>> getPendingFromJson(
    String? json,
  ) {
    if (json == null || json.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(json);

    return List<Map<String, dynamic>>.from(
      decoded.map((e) => Map<String, dynamic>.from(e)),
    );
  }
}
