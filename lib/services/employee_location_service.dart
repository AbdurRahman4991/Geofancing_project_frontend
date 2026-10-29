import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class EmployeeLocationService {
  static const String boxName = 'location_queue';
  static const int batchSize = 10;
  static bool _syncing = false;

  // ============================================================
  // SEND LOCATION
  // ============================================================

  static Future<void> sendLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    String? activityType,
    String? transportMode,
    double? speed,
    DateTime? recordAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');
      if (token == null) {
        print('User not logged in');
        return;
      }


      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();

      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      // Location data
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'activity_type': activityType,
        'transport_mode': transportMode,
        'speed': speed,
        'recorded_at': (recordAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

      // ============================================================
      // NO INTERNET → SAVE TO HIVE
      // ============================================================

      await _saveOffline(locationData);
      if (hasInternet && Hive.box(boxName).length >= batchSize) {
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
  // SEND A LOCATION BATCH TO SERVER
  // ============================================================

  static Future<bool> _sendBatchToServer({
    required List<Map<String, dynamic>> locations,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/employee-locations/batch',
      );

      final headers = {
        ...ApiConfig.headers,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {'locations': locations};

      print('========== LOCATION BATCH API ==========');
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
      print('Send location batch error: $e');

      return false;
    }
  }

  // ============================================================
  // SYNC OFFLINE LOCATIONS
  // ============================================================

  static Future<void> syncOfflineLocations(
    String token,
  ) async {
    if (_syncing) return;
    _syncing = true;
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

      final keys = box.keys.toList();
      for (var offset = 0; offset < keys.length; offset += batchSize) {
        final batchKeys = keys.skip(offset).take(batchSize).toList();
        final locations = <Map<String, dynamic>>[];
        for (final key in batchKeys) {
          final storedData = box.get(key);
          if (storedData != null) {
            final item = Map<String, dynamic>.from(storedData);
            final recordedAt = item['recorded_at'] ??
                item['record_at'] ??
                DateTime.now().toUtc().toIso8601String();
            item['recorded_at'] = recordedAt;
            await box.put(key, item);
            locations.add({
              'latitude': item['latitude'],
              'longitude': item['longitude'],
              'accuracy': item['accuracy'],
              'activity_type': item['activity_type'],
              'transport_mode': item['transport_mode'],
              'speed': item['speed'],
              'recorded_at': recordedAt,
            });
          }
        }
        if (locations.isEmpty) continue;

        final success = await _sendBatchToServer(
          locations: locations,
          token: token,
        );
        if (!success) {
          print('Batch failed; keeping ${batchKeys.length} queued locations.');
          break;
        }
        await box.deleteAll(batchKeys);
        print('Synced batch of ${batchKeys.length} locations.');
      }

      print('Remaining offline locations: ${box.length}');
    } catch (e, stackTrace) {
      print('Offline sync error: $e');
      print(stackTrace);
    } finally {
      _syncing = false;
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
