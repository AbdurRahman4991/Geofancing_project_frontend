// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '/plugins/api_config.dart';

// class AttendanceApiService {
//   /// ✅ Employee Check-In
//   static Future<String> checkIn({
//     required double latitude,
//     required double longitude,
//     required String deviceId,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('access_token');

//       if (token == null) {
//         return "User not logged in!";
//       }

//       final url = Uri.parse('${ApiConfig.baseUrl}/check-in');
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       };

//       final body = jsonEncode({
//         'latitude': latitude,
//         'longitude': longitude,
//         'device_id': deviceId,
//       });

//       final response = await http.post(url, headers: headers, body: body);
//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return data['message'] ?? "Checked in successfully!";
//       } else {
//         return data['message'] ?? "Check-in failed!";
//       }
//     } catch (e) {
//       return "Error: $e";
//     }
//   }

//   /// 🔴 Employee Check-Out
//   static Future<String> checkOut({
//     required double latitude,
//     required double longitude,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('access_token');

//       if (token == null) {
//         return "User not logged in!";
//       }

//       final url = Uri.parse('${ApiConfig.baseUrl}/check-out');
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       };

//       final body = jsonEncode({
//         'latitude': latitude,
//         'longitude': longitude,
//       });

//       final response = await http.post(url, headers: headers, body: body);
//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return data['message'] ?? "Checked out successfully!";
//       } else {
//         return data['message'] ?? "Check-out failed!";
//       }
//     } catch (e) {
//       return "Error: $e";
//     }
//   }
// }
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

      if (token == null || token.isEmpty) {
        return "User not logged in!";
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/check-in');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'device_id': deviceId,
      });

      print("================================");
      print("CHECK-IN URL: $url");
      print("CHECK-IN BODY: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print("CHECK-IN STATUS: ${response.statusCode}");
      print("CHECK-IN CONTENT TYPE: ${response.headers['content-type']}");
      print("CHECK-IN RESPONSE: ${response.body}");

      // ✅ First check HTTP status
      if (response.statusCode != 200 && response.statusCode != 201) {
        return _extractMessage(
          response.body,
          "Check-in failed! (${response.statusCode})",
        );
      }

      // ✅ Then decode JSON safely
      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data['message']?.toString() ??
              "Checked in successfully!";
        }

        return "Checked in successfully!";
      } catch (e) {
        print("CHECK-IN JSON ERROR: $e");

        return "Server returned invalid response!";
      }
    } catch (e) {
      print("CHECK-IN ERROR: $e");
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

      if (token == null || token.isEmpty) {
        return "User not logged in!";
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/check-out');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      });

      print("================================");
      print("CHECK-OUT URL: $url");
      print("CHECK-OUT BODY: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print("CHECK-OUT STATUS: ${response.statusCode}");
      print("CHECK-OUT CONTENT TYPE: ${response.headers['content-type']}");
      print("CHECK-OUT RESPONSE: ${response.body}");

      // ✅ First check HTTP status
      if (response.statusCode != 200 && response.statusCode != 201) {
        return _extractMessage(
          response.body,
          "Check-out failed! (${response.statusCode})",
        );
      }

      // ✅ Then decode JSON safely
      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data['message']?.toString() ??
              "Checked out successfully!";
        }

        return "Checked out successfully!";
      } catch (e) {
        print("CHECK-OUT JSON ERROR: $e");

        return "Server returned invalid response!";
      }
    } catch (e) {
      print("CHECK-OUT ERROR: $e");
      return "Error: $e";
    }
  }

  /// ✅ Extract Laravel JSON error message safely
  static String _extractMessage(
    String responseBody,
    String defaultMessage,
  ) {
    try {
      final data = jsonDecode(responseBody);

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          return data['message'].toString();
        }

        if (data['errors'] != null) {
          return data['errors'].toString();
        }
      }

      return defaultMessage;
    } catch (e) {
      // ❗ Response is HTML, not JSON
      print("NON-JSON RESPONSE: $responseBody");

      return defaultMessage;
    }
  }
}