import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/device_helper.dart';
import '../helpers/network_helper.dart';
import '../services/attendance_service_api.dart';
import '../services/offline_attendance_service.dart';

class AttendanceManager {
  final List<dynamic> _geofencingList = [];

  /// Getter
  List<dynamic> get geofencingList => _geofencingList;

  /// Geofence আছে কিনা
  bool get hasGeofence => _geofencingList.isNotEmpty;

  /// Load geofence from SharedPreferences
  Future<void> loadGeofence() async {
    final prefs = await SharedPreferences.getInstance();

    final geoJson = prefs.getString("geofancing");

    _geofencingList.clear();

    if (geoJson != null && geoJson.isNotEmpty) {
      _geofencingList.addAll(jsonDecode(geoJson));
    }
  }

  /// Sync Offline Attendance
  Future<void> syncOfflineAttendance() async {
    final online = await NetworkHelper.hasInternet();

    if (!online) return;

    final data =
        await OfflineAttendanceService.getPendingAttendance();

    if (data == null) return;

    String message = "";

    if (data["type"] == "check_in") {
      message = await AttendanceApiService.checkIn(
        latitude: data["latitude"],
        longitude: data["longitude"],
        deviceId: data["device_id"],
      );
    } else if (data["type"] == "check_out") {
      message = await AttendanceApiService.checkOut(
        latitude: data["latitude"],
        longitude: data["longitude"],
      );
    }

    if (message.toLowerCase().contains("success")) {
      await OfflineAttendanceService.clear();
    }
  }

  /// Check if user is inside office
  bool isInsideOffice(Position position) {
    if (_geofencingList.isEmpty) return false;

    for (final geo in _geofencingList) {
      final distance = Geolocator.distanceBetween(
        double.parse(geo["latitude"].toString()),
        double.parse(geo["longitude"].toString()),
        position.latitude,
        position.longitude,
      );

      final radius =
          double.parse(geo["radius"].toString());

      if (distance <= radius) {
        return true;
      }
    }

    return false;
  }

  /// Check In
  Future<String> checkIn(Position position) async {
    final deviceId =
        await DeviceHelper.getDeviceId();

    final online =
        await NetworkHelper.hasInternet();

    if (!online) {
      await OfflineAttendanceService.saveCheckIn(
        latitude: position.latitude,
        longitude: position.longitude,
        deviceId: deviceId,
      );

      return "Checked In (Offline)";
    }

    return await AttendanceApiService.checkIn(
      latitude: position.latitude,
      longitude: position.longitude,
      deviceId: deviceId,
    );
  }

  /// Check Out
  Future<String> checkOut(Position position) async {
    final online =
        await NetworkHelper.hasInternet();

    if (!online) {
      await OfflineAttendanceService.saveCheckOut(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return "Checked Out (Offline)";
    }

    return await AttendanceApiService.checkOut(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}