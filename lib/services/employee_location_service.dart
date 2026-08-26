import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class EmployeeLocationService {
  static const String boxName = 'location_queue';

  // ============================================================
  // SEND LOCATION
  // ============================================================

  static Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');
      final userJson = prefs.getString('user');

      if (token == null || userJson == null) {
        print('User not logged in');
        return;
      }

      final user = jsonDecode(userJson);
      final employeeId = user['employee']['id'];

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();

      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      // Location data
      final locationData = {
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      };

      // ============================================================
      // NO INTERNET → SAVE TO HIVE
      // ============================================================

      if (!hasInternet) {
        await _saveOffline(locationData);

        print('================================');
        print('NO INTERNET');
        print('Location saved offline');
        print('Latitude: $latitude');
        print('Longitude: $longitude');
        print('================================');

        return;
      }

      // ============================================================
      // INTERNET AVAILABLE → SEND TO API
      // ============================================================

      final success = await _sendToServer(
        locationData: locationData,
        token: token,
      );

      // API failed → save to Hive
      if (!success) {
        await _saveOffline(locationData);

        print('API failed.');
        print('Location saved offline.');
      } else {
        print('Location successfully sent to server.');

        // Existing offline locations sync
        await syncOfflineLocations(token);
      }
    } catch (e, stackTrace) {
      print('Location Service Error: $e');
      print(stackTrace);
    }
  }

  // ============================================================
  // SAVE LOCATION OFFLINE
  // ============================================================

  static Future<void> _saveOffline(
    Map<String, dynamic> locationData,
  ) async {
    try {
      final box = Hive.box(boxName);

      await box.add(locationData);

      print('Offline location count: ${box.length}');
    } catch (e) {
      print('Hive save error: $e');
    }
  }

  // ============================================================
  // SEND SINGLE LOCATION TO SERVER
  // ============================================================

  static Future<bool> _sendToServer({
    required Map<String, dynamic> locationData,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/employee-locations',
      );

      final headers = {
        ...ApiConfig.headers,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'employee_id': locationData['employee_id'],
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'captured_at': locationData['captured_at'],
      };

      print('========== LOCATION API ==========');
      print('URL: $url');
      print('Body: ${jsonEncode(body)}');
      print('==================================');

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      return response.statusCode >= 200 &&
          response.statusCode < 300;
    } catch (e) {
      print('Send location error: $e');

      return false;
    }
  }

  // ============================================================
  // SYNC OFFLINE LOCATIONS
  // ============================================================

  static Future<void> syncOfflineLocations(
    String token,
  ) async {
    try {
      final box = Hive.box(boxName);

      if (box.isEmpty) {
        print('No offline locations to sync.');
        return;
      }

      print('================================');
      print('SYNCING OFFLINE LOCATIONS');
      print('Total: ${box.length}');
      print('================================');

      // Copy keys because we will delete records
      final keys = box.keys.toList();

      for (final key in keys) {
        try {
          final storedData = box.get(key);

          if (storedData == null) {
            continue;
          }

          final locationData =
              Map<String, dynamic>.from(storedData);

          print('Sending offline location: $key');

          final success = await _sendToServer(
            locationData: locationData,
            token: token,
          );

          if (success) {
            // API success → remove from Hive
            await box.delete(key);

            print(
              'Offline location synced successfully: $key',
            );
          } else {
            print(
              'Failed to sync: $key',
            );

            // Network/server problem হলে stop করব
            break;
          }
        } catch (e) {
          print('Error syncing location $key: $e');
          break;
        }
      }

      print('Remaining offline locations: ${box.length}');
    } catch (e, stackTrace) {
      print('Offline sync error: $e');
      print(stackTrace);
    }
  }

  // ============================================================
  // CHECK INTERNET AND SYNC
  // ============================================================

  static Future<void> syncIfInternetAvailable() async {
    try {
      final connectivity =
          await Connectivity().checkConnectivity();

      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        print('No internet. Sync skipped.');
        return;
      }

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('access_token');

      if (token == null) {
        print('No access token. Sync skipped.');
        return;
      }

      await syncOfflineLocations(token);
    } catch (e, stackTrace) {
      print('Sync error: $e');
      print(stackTrace);
    }
  }
}