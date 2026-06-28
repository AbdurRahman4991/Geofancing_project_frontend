import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';

class GeofenceUpdateService {
  /// =========================
  /// 🔐 AUTH HEADER
  /// =========================
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    };
  }

  /// =========================
  /// ✏️ UPDATE GEOFENCE
  /// =========================
  static Future<bool> updateGeofence({
    required int id,
    required int companyId,
    required int userId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final headers = await _authHeaders();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/geofences/$id'),
        headers: headers,
        body: jsonEncode({
          "company_id": companyId,
          "user_id": userId,
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius,
        }),
      );

      print("UPDATE RESPONSE: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }
}