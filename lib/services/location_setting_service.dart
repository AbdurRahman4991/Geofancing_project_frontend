import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';

class GeofenceService {

  // static Future<Map<String, String>> _headers() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('access_token');
  // print("TOKEN => $token");

  //   return {
  //     ...ApiConfig.headers,
  //     'Authorization': 'Bearer $token',
  //   };
  // }
  static Future<Map<String, String>> _headers() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  print("TOKEN => $token");

  return {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  };
}

  /// ============================
  /// Sync Geofence To SharedPreference
  /// ============================
  static Future<void> syncGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/geofences'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        List<dynamic> geofenceList = jsonDecode(response.body);

        // Attendance page এই key use করছে
        await prefs.setString(
          'geofancing',
          jsonEncode(geofenceList),
        );

        print("Geofence Synced Successfully");
      }
    } catch (e) {
      print("Sync Error : $e");
    }
  }

  /// ============================
  /// Create
  /// ============================
  static Future<bool> createGeofence({
    required int companyId,
    required int userId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/geofences'),
        headers: await _headers(),
        body: jsonEncode({
          "company_id": companyId,
          "user_id": userId,
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius,
        }),
      );

      print("Status Code : ${response.statusCode}");
      print("Response : ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        // SharedPreference Update
        await syncGeofences();

        return true;
      }

      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// ============================
  /// Update
  /// ============================
  static Future<bool> updateGeofence({
    required int id,
    required int companyId,
    required int userId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/geofences/$id'),
        headers: await _headers(),
        body: jsonEncode({
          "company_id": companyId,
          "user_id": userId,
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius,
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {

        // SharedPreference Update
        await syncGeofences();

        return true;
      }

      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// ============================
  /// List
  /// ============================
  static Future<List<dynamic>> getGeofences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/geofences'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }
}

