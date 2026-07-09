// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import '../plugins/api_config.dart';

// class EmployeeLocationService {
//   static Future<void> sendLocation({
//     required double latitude,
//     required double longitude,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();

//       final token = prefs.getString('access_token');
//       final userJson = prefs.getString('user');

//       if (token == null || userJson == null) {
//         print("User not logged in");
//         return;
//       }
//       print(token);
//       final user = jsonDecode(userJson);

//       final employeeId = user['employee']['id'];

//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/employee-locations'),
//         headers: {
//           ...ApiConfig.headers,
//           'Authorization': 'Bearer $token',
//         },
//         print({
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         });
//         body: jsonEncode({
//           "employee_id": employeeId,
//           "latitude": latitude,
//           "longitude": longitude,
//         }),
//       );

//       print("Status: ${response.statusCode}");
//       print(response.body);
//     } catch (e) {
//       print("Location API Error: $e");
//     }
//   }
// }

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

      final url = Uri.parse('${ApiConfig.baseUrl}/employee-locations');

      final headers = {
        ...ApiConfig.headers,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        "employee_id": employeeId,
        "latitude": latitude,
        "longitude": longitude,
      };

      // Debug
      print("========== LOCATION API ==========");
      print("URL: $url");
      print("Token: >$token<");
      print("Headers: $headers");
      print("Body: ${jsonEncode(body)}");
      print("==================================");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
    } catch (e, stackTrace) {
      print("Location API Error: $e");
      print(stackTrace);
    }
  }
}