import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/plugins/api_config.dart';

class AttendanceApiService {
  /// ✅ Employee Check-In
  static Future<String> checkIn({
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return "User not logged in!";
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/check-in');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'device_id': deviceId,
      });

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? "Checked in successfully!";
      } else {
        return data['message'] ?? "Check-in failed!";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// 🔴 Employee Check-Out
  static Future<String> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return "User not logged in!";
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/check-out');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['message'] ?? "Checked out successfully!";
      } else {
        return data['message'] ?? "Check-out failed!";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
