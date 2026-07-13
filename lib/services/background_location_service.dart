// import 'dart:async';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:geolocator/geolocator.dart';
// import '../services/employee_location_service.dart';

// class BackgroundLocationService {
//   static Future<void> initializeService() async {
//     final service = FlutterBackgroundService();

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         isForegroundMode: true,
//         autoStart: true,
//         foregroundServiceNotificationId: 100,
//         initialNotificationTitle: "Attendance Tracking",
//         initialNotificationContent: "Location tracking running",
//       ),
//       iosConfiguration: IosConfiguration(),
//     );
//     // যদি service আগে থেকে চালু না থাকে তাহলে start করুন
//     bool isRunning = await service.isRunning();

//     if (!isRunning) {
//       await service.startService();
//       print("Background Service Started");
//     } else {
//       print("Background Service Already Running");
//     }
//   }
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) {
//    print("===== Background Service onStart =====");

//   service.on("stopService").listen((event) {
//     service.stopSelf();
//   });

//   Timer.periodic(
//     const Duration(seconds: 300),
//     (timer) async {
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );

//         await EmployeeLocationService.sendLocation(
//           latitude: position.latitude,
//           longitude: position.longitude,
//         );        
//       } catch (e) {
//         print(e);
//       }
//     },
//   );
// }

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../services/AttendanceManager.dart';
import '../services/employee_location_service.dart';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {

static Future<void> createNotificationChannel() async {

  const AndroidNotificationChannel channel =
      AndroidNotificationChannel(

    'attendance_channel',

    'Attendance Tracking',

    description:
        'Employee location tracking',

    importance:
        Importance.low,

  );


  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();


  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

}

  static Future<void> initializeService() async {
  await createNotificationChannel();
  final service = FlutterBackgroundService();


  await service.configure(

    androidConfiguration:
        AndroidConfiguration(

      onStart: onStart,

      autoStart: true,

      isForegroundMode: true,


      notificationChannelId:
          'attendance_channel',


      initialNotificationTitle:
          'Attendance Tracking',


      initialNotificationContent:
          'Location running',


      foregroundServiceNotificationId:
          100,

    ),


    iosConfiguration:
        IosConfiguration(),

  );


  bool running =
      await service.isRunning();


  if (!running) {

    await service.startService();

    print(
      "Background Service Started"
    );

  }

}




  @pragma('vm:entry-point')
  static void onStart(
      ServiceInstance service) async {

    DartPluginRegistrant.ensureInitialized();
    if (service is AndroidServiceInstance) {

    service.setAsForegroundService();

  }


  print("===== BACKGROUND SERVICE STARTED =====");



    final attendanceManager =
        AttendanceManager();



    // Load saved geofence

    await attendanceManager
        .loadGeofence();



    bool checkedIn = false;



    service.on("stopService")
        .listen((event) {

      service.stopSelf();

    });





    Timer.periodic(
  const Duration(seconds: 3000),
  (timer) async {

    print("===== TIMER RUNNING =====");

    try {

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );


      print(
        "LAT: ${position.latitude}"
      );

      print(
        "LNG: ${position.longitude}"
      );


      await EmployeeLocationService.sendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );


      print("Location Sent");



      bool inside =
          attendanceManager.isInsideOffice(position);


      print(
        "Inside Office: $inside"
      );


      if (inside && !checkedIn) {

        final message =
            await attendanceManager.checkIn(position);


        print(
          "CHECK IN: $message"
        );


      }


      if (!inside && checkedIn) {

        final message =
            await attendanceManager.checkOut(position);


        print(
          "CHECK OUT: $message"
        );

      }


    } catch(e){

      print(
        "BACKGROUND ERROR: $e"
      );

    }

  },
);

  }

}