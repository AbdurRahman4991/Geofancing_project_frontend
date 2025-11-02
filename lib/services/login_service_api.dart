

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // <-- import this
import '/plugins/api_config.dart';

class ApiService {
  static Future<String?> loginUser(
      String employee_id, String phone, String device_id, String latitude, String longitude) async {
    try {
      var url = Uri.parse('${ApiConfig.baseUrl}/login');

      var response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'employee_id': employee_id,
          'phone': phone,
          'device_id': device_id,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 🔑 Token কে SharedPreferences এ সংরক্ষণ করা
        String token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

         if (data['geofancing'] != null) {
            await prefs.setString('geofancing', jsonEncode(data['geofancing']));
          }

        return data['message'] ?? "Login successful.";
      } else if (response.statusCode == 422) {
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final firstError = data['errors'].values.first[0];
          return firstError;
        }
        return data['message'] ?? "Validation failed";
      } else {
        return data['message'] ?? "Something went wrong.";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // 🔄 Token retrieve করার জন্য helper
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 🗑️ Token delete করার জন্য helper (logout এর জন্য)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
