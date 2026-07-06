import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../services/employee_location_service.dart';

class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        foregroundServiceNotificationId: 100,
        initialNotificationTitle: "Attendance Tracking",
        initialNotificationContent: "Location tracking running",
      ),
      iosConfiguration: IosConfiguration(),
    );
    // যদি service আগে থেকে চালু না থাকে তাহলে start করুন
    bool isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
      print("Background Service Started");
    } else {
      print("Background Service Already Running");
    }
  }
}


@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  Timer.periodic(
    const Duration(seconds: 30),
    (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print(
          "${position.latitude}, ${position.longitude}",
        );

        await EmployeeLocationService.sendLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        print(e);
      }
    },
  );
}
