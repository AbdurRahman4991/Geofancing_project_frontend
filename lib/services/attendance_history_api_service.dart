
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/plugins/api_config.dart';

class AttendanceHistoryApiService {
  /// ✅ Get Attendance with Pagination
  static Future<Map<String, dynamic>?> getAttendanceHistory({
    String? month,
    String? status,
    String? late,
    String? year,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        print("⚠️ No token found!");
        return null;
      }

      final queryParams = <String, String>{
        'page': '$page',
        if (month != null && month.isNotEmpty) 'month': month,
        if (status != null && status.isNotEmpty) 'status': status,
        if (late != null && late.isNotEmpty) 'late': late,
        if (year != null && year.isNotEmpty) 'year': year,
      };

      final uri = Uri.parse(
        "${ApiConfig.baseUrl}/attendance/history",
      ).replace(queryParameters: queryParams);

      print("🌐 Fetching: $uri");

      final headers = {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Server Error: ${response.statusCode}");
        print(response.body);
        return null;
      }
    } catch (e) {
      print("🚨 Error: $e");
      return null;
    }
  }
}