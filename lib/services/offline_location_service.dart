import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class EmployeeLocationService {
  static const String boxName = 'location_queue';

  /// Main method
  /// Internet থাকলে সরাসরি API-তে পাঠাবে।
  /// Internet না থাকলে Hive-এ save করবে।
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

      final locationData = {
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      };

      final connectivity = await Connectivity().checkConnectivity();

      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        await _saveOffline(locationData);

        print('No internet. Location saved locally.');
        return;
      }

      final success = await _sendToServer(
        locationData: locationData,
        token: token,
      );

      if (!success) {
        await _saveOffline(locationData);
        print('API failed. Location saved locally.');
      }

      // API success হলে আগের offline data-ও sync করবে
      if (success) {
        await syncOfflineLocations(token);
      }
    } catch (e, stackTrace) {
      print('Location Service Error: $e');
      print(stackTrace);
    }
  }

  /// Save location to Hive
  static Future<void> _saveOffline(
    Map<String, dynamic> locationData,
  ) async {
    final box = Hive.box(boxName);

    await box.add(locationData);
  }

  /// Send single location to server
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

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('Location API Status: ${response.statusCode}');
      print('Location API Response: ${response.body}');

      return response.statusCode >= 200 &&
          response.statusCode < 300;
    } catch (e) {
      print('Send location error: $e');
      return false;
    }
  }

  /// Sync all offline locations
  static Future<void> syncOfflineLocations(String token) async {
    try {
      final box = Hive.box(boxName);

      if (box.isEmpty) {
        print('No offline locations to sync.');
        return;
      }

      print('Syncing ${box.length} offline locations...');

      final keys = box.keys.toList();

      for (final key in keys) {
        final data = Map<String, dynamic>.from(
          box.get(key),
        );

        final success = await _sendToServer(
          locationData: data,
          token: token,
        );

        if (success) {
          await box.delete(key);

          print('Offline location synced: $key');
        } else {
          print('Sync failed. Keeping location: $key');

          // Network/server problem হলে পরের location-এ না গিয়ে
          // এখানেই stop করা ভালো।
          break;
        }
      }

      print('Remaining offline locations: ${box.length}');
    } catch (e, stackTrace) {
      print('Offline sync error: $e');
      print(stackTrace);
    }
  }

  /// Check and sync manually
  static Future<void> syncIfInternetAvailable() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return;
      }

      await syncOfflineLocations(token);
    } catch (e) {
      print('Connectivity sync error: $e');
    }
  }
}