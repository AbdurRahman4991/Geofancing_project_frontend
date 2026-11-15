
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/plugins/api_config.dart';

class MarketVisitApiService {

  /// Create Market Visit (Automatic Check-In / Check-Out)
  static Future<Map<String, dynamic>?> createMarketVisit({
    required double latitude,
    required double longitude,
    String? deviceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        print("⚠️ No token found!");
        return null;
      }

      final uri = Uri.parse(
        "${ApiConfig.baseUrl}/market-visits",
      );

      print("🌐 Sending Request: $uri");

      final headers = {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        if (deviceId != null && deviceId.isNotEmpty)
          'device_id': deviceId,
      });

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
      );

      print("📡 Status Code: ${response.statusCode}");
      print("📩 Response: ${response.body}");

      // Decode Response
      Map<String, dynamic> responseData;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else {
          responseData = {
            'data': decoded,
          };
        }
      } catch (_) {
        responseData = {
          'message': response.body,
        };
      }

      // Add HTTP Status Code
      responseData['_http_status_code'] = response.statusCode;

      // Success
      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        print("✅ Market Visit Created Successfully!");
        return responseData;
      }

      // Permission Denied
      else if (response.statusCode == 403) {
        print("⛔ Permission denied!");
        return responseData;
      }

      // Validation Error
      else if (response.statusCode == 422) {
        print("⚠️ Validation Error!");
        return responseData;
      }

      // Unauthorized
      else if (response.statusCode == 401) {
        print("🔒 Unauthorized! Please login again.");
        return responseData;
      }

      // Other Server Errors
      else {
        print("❌ Server Error: ${response.statusCode}");
        return responseData;
      }

    } catch (e) {
      print("🚨 Market Visit API Error: $e");
      return null;
    }
  }
}
