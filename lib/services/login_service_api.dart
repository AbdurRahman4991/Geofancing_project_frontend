

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart'; // <-- import this
// import '/plugins/api_config.dart';
//   import 'package:flutter_background_service/flutter_background_service.dart';

// class ApiService {
//   static Future<String?> loginUser(
//       String employee_id, String phone, String device_id, String latitude, String longitude) async {
//     try {
//       var url = Uri.parse('${ApiConfig.baseUrl}/login');

//       var response = await http.post(
//         url,
//         headers: ApiConfig.headers,
//         body: jsonEncode({
//           'employee_id': employee_id,
//           'phone': phone,
//           'device_id': device_id,
//           'latitude': latitude,
//           'longitude': longitude,
//         }),
//       );

//       var data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         // 🔑 Token কে SharedPreferences এ সংরক্ষণ করা
//         String token = data['access_token'];
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('access_token', token);

//          if (data['geofancing'] != null) {
//             await prefs.setString('geofancing', jsonEncode(data['geofancing']));
//           }
          
//         // User save
//         if (data['user'] != null) {
//           await prefs.setString(
//             'user',
//             jsonEncode(data['user']),
//           );
//         }

//         return data['message'] ?? "Login successful.";
//       } else if (response.statusCode == 422) {
//         if (data['errors'] != null && data['errors'].isNotEmpty) {
//           final firstError = data['errors'].values.first[0];
//           return firstError;
//         }
//         return data['message'] ?? "Validation failed";
//       } else {
//         return data['message'] ?? "Something went wrong.";
//       }
//     } catch (e) {
//       return "Error: $e";
//     }
//   }

//   // 🔄 Token retrieve করার জন্য helper
//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('access_token');
//   }

//   // 🗑️ Token delete করার জন্য helper (logout এর জন্য)
//   // static Future<void> logout() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   await prefs.remove('access_token');
//   // }


// static Future<void> logout() async {
//   final prefs = await SharedPreferences.getInstance();

//   await prefs.remove('access_token');
//   await prefs.remove('user');
//   await prefs.remove('geofancing');

//   final service = FlutterBackgroundService();

//   if (await service.isRunning()) {
//     service.invoke("stopService");
//   }
// }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/plugins/api_config.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class ApiService {
  static Future<String?> loginUser(
    String email,
    String password,
    String deviceId,
    String latitude,
    String longitude,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/login',
      );

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'device_id': deviceId.trim(),
          'latitude': latitude.trim(),
          'longitude': longitude.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      // =========================
      // Login Successful
      // =========================
      if (response.statusCode == 200) {
        final token = data['access_token'];

        if (token == null) {
          return 'Access token not received.';
        }

        final prefs = await SharedPreferences.getInstance();

        // Save token
        await prefs.setString(
          'access_token',
          token.toString(),
        );

        // Save geofencing data
        if (data['geofancing'] != null) {
          await prefs.setString(
            'geofancing',
            jsonEncode(data['geofancing']),
          );
        }

        // Save user
        if (data['user'] != null) {
          await prefs.setString(
            'user',
            jsonEncode(data['user']),
          );
        }

        return data['message'] ??
            'Login successful.';
      }

      // =========================
      // Validation Error
      // =========================
      if (response.statusCode == 422) {
        final errors = data['errors'];

        if (errors != null &&
            errors is Map &&
            errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List &&
              firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }

        return data['message'] ??
            'Validation failed.';
      }

      // =========================
      // Unauthorized
      // =========================
      if (response.statusCode == 401) {
        return data['message'] ??
            'Invalid email or password.';
      }

      // =========================
      // Server Error
      // =========================
      if (response.statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      // =========================
      // Other Error
      // =========================
      return data['message'] ??
          'Something went wrong.';
    } catch (e) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
  }

  // =========================
  // Get Token
  // =========================
  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('access_token');
  }

  // =========================
  // Logout
  // =========================
  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('user');
    await prefs.remove('geofancing');

    final service = FlutterBackgroundService();

    if (await service.isRunning()) {
      service.invoke("stopService");
    }
  }
}