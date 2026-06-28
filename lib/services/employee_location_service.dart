import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class EmployeeLocationService {
  static Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');
      final userJson = prefs.getString('user');

      if (token == null || userJson == null) {
        print("User not logged in");
        return;
      }

      final user = jsonDecode(userJson);

      final employeeId = user['employee']['id'];

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/employee-locations'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "employee_id": employeeId,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      print("Status: ${response.statusCode}");
      print(response.body);
    } catch (e) {
      print("Location API Error: $e");
    }
  }
}