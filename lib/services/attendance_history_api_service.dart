import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/plugins/api_config.dart';

class AttendanceHistoryApiService {
  /// ✅ Attendance History Get API
  static Future<Map<String, dynamic>?> getAttendanceHistory({
    String? month,
    String? status,
    String? late,
    String? year,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        print("⚠️ No token found!");
        return null;
      }

      // ✅ URL তৈরি — query parameter সহ
      String url = '${ApiConfig.baseUrl}/attendance/history?page=$page';

      if (month != null && month.isNotEmpty) {
        url += '&month=$month';
      }
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }
      if (late != null && late.isNotEmpty) {
        url += '&late=$late';
      }
      if (year != null && year.isNotEmpty) {
        url += '&year=$year';
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // pagination object return করবে
      } else {
        print("❌ Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🚨 Error: $e");
      return null;
    }
  }
}

