import 'package:hive_flutter/hive_flutter.dart';

class OfflineAttendanceService {
  static final box = Hive.box('attendance_offline');
  static Future<void> saveCheckIn({
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    await box.put('attendance', {
      "type": "check_in",
      "latitude": latitude,
      "longitude": longitude,
      "device_id": deviceId,
      "time": DateTime.now().toIso8601String(),
    });
  }
  static Future<void> saveCheckOut({
    required double latitude,
    required double longitude,
  }) async {
    await box.put('attendance', {
      "type": "check_out",
      "latitude": latitude,
      "longitude": longitude,
      "time": DateTime.now().toIso8601String(),
    });
  }
  static Map? getPendingAttendance(){
    final data = box.get('attendance');
    if(data == null){
      return null;
    }
    return Map<String,dynamic>.from(data);
  }
  static Future<void> clear() async {
    await box.delete('attendance');
  }
}