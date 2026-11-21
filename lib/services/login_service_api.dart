
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
      final url = Uri.parse('${ApiConfig.baseUrl}/login');

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

      final decoded = _decodeResponse(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      // =====================================
      // LOGIN SUCCESSFUL
      // =====================================

      if (response.statusCode == 200) {
        final token = data['access_token'];

        if (token == null) {
          return 'Access token not received.';
        }

        final prefs = await SharedPreferences.getInstance();

        // =====================================
        // SAVE ACCESS TOKEN
        // =====================================

        await prefs.setString(
          'access_token',
          token.toString(),
        );

        // =====================================
        // SAVE USER DATA
        // =====================================

        if (data['user'] != null) {
          await prefs.setString(
            'user',
            jsonEncode(data['user']),
          );
        }

        // =====================================
        // SAVE HIERARCHY ASSIGNMENTS
        // =====================================

        final assignments =
            data['user']?['hierarchy_assignments'];

        if (assignments is List) {
          await prefs.setString(
            'hierarchy_assignments',
            jsonEncode(assignments),
          );
        } else {
          await prefs.remove('hierarchy_assignments');
        }

        // =====================================
        // SAVE GEOFENCING DATA
        // =====================================

        if (data['geofancing'] != null) {
          await prefs.setString(
            'geofancing',
            jsonEncode(data['geofancing']),
          );
        } else {
          await prefs.setString('geofancing', '[]');
        }

        // =====================================
        // PRINT SAVED DATA
        // =====================================

        print('\n');
        print('======================================');
        print('       LOGIN SUCCESSFUL');
        print('======================================');

        // Access Token (masked)
        final savedToken = prefs.getString('access_token');

        print('\nACCESS TOKEN:');
        if (savedToken != null && savedToken.length > 8) {
          print('${savedToken.substring(0, 4)}********');
        } else {
          print('Token saved');
        }

        // User Data
        print('\nUSER DATA:');

        final savedUser = prefs.getString('user');

        if (savedUser != null) {
          final prettyUser = const JsonEncoder.withIndent('  ')
              .convert(jsonDecode(savedUser));

          print(prettyUser);
        }

        // Hierarchy Assignments
        print('\nHIERARCHY ASSIGNMENTS:');

        final savedHierarchy =
            prefs.getString('hierarchy_assignments');

        if (savedHierarchy != null) {
          final prettyHierarchy =
              const JsonEncoder.withIndent('  ')
                  .convert(jsonDecode(savedHierarchy));

          print(prettyHierarchy);
        } else {
          print('No hierarchy assignments found.');
        }

        // Geofencing
        print('\nGEOFENCING DATA:');

        final savedGeofencing =
            prefs.getString('geofancing');

        if (savedGeofencing != null) {
          final prettyGeofencing =
              const JsonEncoder.withIndent('  ')
                  .convert(jsonDecode(savedGeofencing));

          print(prettyGeofencing);
        }

        // =====================================
        // PRINT IMPORTANT IDs
        // =====================================

        print('\nSAVED IMPORTANT IDS:');

        if (data['user'] != null) {
          print('User ID: ${data['user']['id']}');

          print(
            'Company ID: ${data['user']['employee']?['company_id']}',
          );
        }

        if (assignments is List) {
          for (final assignment in assignments) {
            print(
              'Hierarchy Node ID: ${assignment['hierarchy_node_id']}',
            );
          }
        }

        print('\n======================================');
        print('       ALL DATA SAVED SUCCESSFULLY');
        print('======================================\n');

        return data['message'] ?? 'Login successful.';
      }

      // =====================================
      // VALIDATION ERROR
      // =====================================

      if (response.statusCode == 422) {
        final errors = data['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }

        return data['message'] ?? 'Validation failed.';
      }

      // =====================================
      // UNAUTHORIZED
      // =====================================

      if (response.statusCode == 401) {
        return data['message'] ??
            'Invalid email or password.';
      }

      // =====================================
      // SERVER ERROR
      // =====================================

      if (response.statusCode >= 500) {
        return _responseMessage(
          data,
          'Server error (${response.statusCode}). Please try again later.',
        );
      }

      return _responseMessage(data, 'Something went wrong.');

    } catch (e) {
      print('Login Error: $e');

      return 'Unable to connect to server. Please check your internet connection.';
    }
  }

  static dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _responseMessage(
    Map<String, dynamic> data,
    String fallback,
  ) {
    final message = data['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }

    return fallback;
  }

  // =====================================
  // GET TOKEN
  // =====================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('access_token');
  }

  // =====================================
  // LOGOUT
  // =====================================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('user');
    await prefs.remove('geofancing');
    await prefs.remove('hierarchy_assignments');

    final service = FlutterBackgroundService();

    if (await service.isRunning()) {
      service.invoke('stopService');
    }

    print('Logout Successful');
    print('All saved login data removed.');
  }
}
