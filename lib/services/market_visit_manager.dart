
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/device_helper.dart';
import '../helpers/network_helper.dart';
import '../services/market_visit_service.dart';
import '../services/offline_market_visit_service.dart';

class MarketVisitManager {
  final List<dynamic> _geofencingList = [];

  bool _isSyncing = false;

  /// Getter
  List<dynamic> get geofencingList => _geofencingList;

  bool get hasGeofence => _geofencingList.isNotEmpty;

  /// Load Geofence
  Future<void> loadGeofence() async {
    final prefs = await SharedPreferences.getInstance();

    final geoJson = prefs.getString("geofancing");

    _geofencingList.clear();

    if (geoJson != null && geoJson.isNotEmpty) {
      final decoded = jsonDecode(geoJson);

      if (decoded is List) {
        _geofencingList.addAll(decoded);
      }
    }
  }

  /// Check Geofence
  bool isInsideOffice(Position position) {
    if (_geofencingList.isEmpty) return false;

    for (final geo in _geofencingList) {
      final distance = Geolocator.distanceBetween(
        double.parse(geo["latitude"].toString()),
        double.parse(geo["longitude"].toString()),
        position.latitude,
        position.longitude,
      );

      final radius = double.parse(
        geo["radius"].toString(),
      );

      if (distance <= radius) {
        return true;
      }
    }

    return false;
  }

  /// Create Market Visit
  Future<Map<String, dynamic>?> createMarketVisit(
    Position position,
  ) async {
    final deviceId = await DeviceHelper.getDeviceId();

    final online = await NetworkHelper.hasInternet();

    // Offline: Save Locally
    if (!online) {
      await OfflineMarketVisitService.save(
        latitude: position.latitude,
        longitude: position.longitude,
        deviceId: deviceId,
      );

      return {
        'success': true,
        'offline': true,
        'message': 'Market Visit saved offline!',
      };
    }

    // Online: Send API Request
    return await MarketVisitApiService.createMarketVisit(
      latitude: position.latitude,
      longitude: position.longitude,
      deviceId: deviceId,
    );
  }

  /// Sync Offline Market Visits
  Future<void> syncOfflineMarketVisit() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final online = await NetworkHelper.hasInternet();

      if (!online) return;

      final pending =
          await OfflineMarketVisitService.getPending();

      if (pending.isEmpty) return;

      for (final data in pending) {
        final response =
            await MarketVisitApiService.createMarketVisit(
          latitude: double.parse(
            data['latitude'].toString(),
          ),
          longitude: double.parse(
            data['longitude'].toString(),
          ),
          deviceId: data['device_id']?.toString(),
        );

        if (response == null) {
          break;
        }

        final statusCode =
            response['_http_status_code'];

        // Only successful requests are removed
        if (statusCode == 200 || statusCode == 201) {
          await OfflineMarketVisitService.removeFirst();
        } else {
          // Stop if server returns an error
          break;
        }
      }
    } catch (e) {
      print('Market Visit Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get Pending Visit Count
  Future<int> getPendingVisitCount() async {
    return await OfflineMarketVisitService.pendingCount();
  }
}
