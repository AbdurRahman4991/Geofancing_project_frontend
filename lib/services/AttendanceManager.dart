import 'package:geolocator/geolocator.dart';

import '../helpers/device_helper.dart';
import '../helpers/network_helper.dart';
import '../services/attendance_service_api.dart';
import '../services/offline_attendance_service.dart';

class AttendanceManager {
  /// Sync Offline Attendance
  Future<void> syncOfflineAttendance() async {
    final online = await NetworkHelper.hasInternet();

    if (!online) return;

    final data =
        OfflineAttendanceService.getPendingAttendance();

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
