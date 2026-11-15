
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:geolocator/geolocator.dart';
// import '../services/AttendanceManager.dart';
// import '../services/market_visit_manager.dart';
// import '../services/employee_location_service.dart';
// import 'dart:ui';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/widgets.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// @pragma('vm:entry-point')
// class BackgroundLocationService {

// static Future<void> createNotificationChannel() async {

//   const AndroidNotificationChannel channel =
//       AndroidNotificationChannel(

//     'attendance_channel',

//     'Attendance Tracking',

//     description:
//         'Employee location tracking',

//     importance:
//         Importance.low,

//   );


//   final FlutterLocalNotificationsPlugin plugin =
//       FlutterLocalNotificationsPlugin();


//   await plugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

// }

//   static Future<void> initializeService() async {
//   await createNotificationChannel();
//   final service = FlutterBackgroundService();


//   await service.configure(

//     androidConfiguration:
//         AndroidConfiguration(

//       onStart: onStart,

//       autoStart: true,

//       isForegroundMode: true,


//       notificationChannelId:
//           'attendance_channel',


//       initialNotificationTitle:
//           'Attendance Tracking',


//       initialNotificationContent:
//           'Location running',


//       foregroundServiceNotificationId:
//           100,

//     ),


//     iosConfiguration:
//         IosConfiguration(),

//   );


//   bool running =
//       await service.isRunning();


//   if (!running) {

//     await service.startService();

//     print(
//       "Background Service Started"
//     );

//   }

// }

// @pragma('vm:entry-point')
// static void onStart(ServiceInstance service) async {

//   DartPluginRegistrant.ensureInitialized();

//   // ==============================
//   // HIVE
//   // ==============================

//   await Hive.initFlutter();

//   if (!Hive.isBoxOpen('location_queue')) {
//     await Hive.openBox('location_queue');
//   }

//   // Clear locations stored with the previous payload schema once.
//   final prefs = await SharedPreferences.getInstance();
//   const queueMigrationKey = 'location_queue_recorded_at_migration_v1';
//   if (!(prefs.getBool(queueMigrationKey) ?? false)) {
//     await Hive.box('location_queue').clear();
//     await prefs.setBool(queueMigrationKey, true);
//     print('Cleared old location queue for recorded_at payload migration.');
//   }

//   print("Hive location_queue opened");

//   Timer.periodic(const Duration(seconds: 30), (_) {
//     EmployeeLocationService.syncIfInternetAvailable();
//   });


//   // ==============================
//   // FOREGROUND SERVICE
//   // ==============================

//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//   }

//   print("===== BACKGROUND SERVICE STARTED =====");


//   // ==============================
//   // ATTENDANCE
//   // ==============================

//   final attendanceManager =
//       AttendanceManager();

//   await attendanceManager.loadGeofence();

//   bool checkedIn = false;


//   // ==============================
//   // STOP SERVICE
//   // ==============================

//   service.on("stopService").listen((event) {
//     service.stopSelf();
//   });


//   // ==============================
//   // LOCATION SETTINGS
//   // ==============================

//   final LocationSettings locationSettings = Platform.isAndroid
//       ? AndroidSettings(
//           accuracy: LocationAccuracy.bestForNavigation,
//           distanceFilter: 5,
//           intervalDuration: const Duration(seconds: 5),
//         )
//       : AppleSettings(
//           accuracy: LocationAccuracy.bestForNavigation,
//           activityType: ActivityType.fitness,
//           distanceFilter: 5,
//           pauseLocationUpdatesAutomatically: false,
//         );


//   // ==============================
//   // LOCATION STREAM
//   // ==============================

//   Geolocator.getPositionStream(
//     locationSettings: locationSettings,
//   ).listen(
//     (Position position) async {

//       try {

//         // Ignore fixes that are too imprecise to be useful for route tracking.
//         if (!position.accuracy.isFinite ||
//             position.accuracy < 0 ||
//             position.accuracy > 50) {
//           print("Skipping inaccurate location: ${position.accuracy}m");
//           return;
//         }

//         print("===== LOCATION UPDATED =====");

//         print("LAT: ${position.latitude}");
//         print("LNG: ${position.longitude}");


//         // ==========================
//         // SEND LOCATION
//         // ==========================

//         await EmployeeLocationService.sendLocation(
//           latitude: position.latitude,
//           longitude: position.longitude,
//           accuracy: position.accuracy,
//           speed: position.speed >= 0 ? position.speed : null,
//           recordAt: position.timestamp.toUtc(),
//         );

//         print("Location processing completed");

//         // ==========================
//         // GEOFENCE
//         // ==========================

//         final inside =
//             attendanceManager.isInsideOffice(position);

//         print("Inside Office: $inside");

//         // ==========================
//         // CHECK IN
//         // ==========================

//         if (inside && !checkedIn) {

//           final message =
//               await attendanceManager.checkIn(position);

//           print("CHECK IN: $message");

//           checkedIn = true;
//         }

//         // ==========================
//         // CHECK OUT
//         // ==========================

//         if (!inside && checkedIn) {

//           final message =
//               await attendanceManager.checkOut(position);

//           print("CHECK OUT: $message");

//           checkedIn = false;
//         }

//       } catch (e, stackTrace) {

//         print("BACKGROUND LOCATION ERROR: $e");

//         print(stackTrace);
//       }

//     },
//     onError: (error) {

//       print("LOCATION STREAM ERROR: $error");

//     },
//   );
// }
// }


import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/market_visit_manager.dart';
import '../services/employee_location_service.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {

  static const String channelId = 'market_visit_channel';

  static const String insideGeofenceKey =
      'market_visit_inside_geofence';

  /// ==============================
  /// NOTIFICATION CHANNEL
  /// ==============================

  static Future<void> createNotificationChannel() async {

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      channelId,
      'Market Visit Tracking',
      description: 'Employee market visit tracking',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// ==============================
  /// INITIALIZE SERVICE
  /// ==============================

  static Future<void> initializeService() async {

    await createNotificationChannel();

    final service = FlutterBackgroundService();

    await service.configure(

      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,

        notificationChannelId: channelId,

        initialNotificationTitle: 'Market Visit Tracking',

        initialNotificationContent: 'Location tracking running',

        foregroundServiceNotificationId: 100,
      ),

      iosConfiguration: IosConfiguration(),
    );

    final running = await service.isRunning();

    if (!running) {
      await service.startService();

      print("Market Visit Background Service Started");
    }
  }

  /// ==============================
  /// BACKGROUND SERVICE START
  /// ==============================

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {

    DartPluginRegistrant.ensureInitialized();

    // ==============================
    // HIVE
    // ==============================

    await Hive.initFlutter();

    if (!Hive.isBoxOpen('location_queue')) {
      await Hive.openBox('location_queue');
    }

    // Existing location queue migration
    final prefs = await SharedPreferences.getInstance();

    const queueMigrationKey =
        'location_queue_recorded_at_migration_v1';

    if (!(prefs.getBool(queueMigrationKey) ?? false)) {

      await Hive.box('location_queue').clear();

      await prefs.setBool(queueMigrationKey, true);

      print('Old location queue migration completed.');
    }

    print("Hive location_queue opened");

    // ==============================
    // MARKET VISIT MANAGER
    // ==============================

    final marketVisitManager = MarketVisitManager();

    await marketVisitManager.loadGeofence();

    // Restore previous geofence state
    bool wasInsideGeofence =
        prefs.getBool(insideGeofenceKey) ?? false;

    print("Previous Geofence State: $wasInsideGeofence");

    // ==============================
    // OFFLINE MARKET VISIT SYNC
    // ==============================

    // Sync immediately when service starts
    await marketVisitManager.syncOfflineMarketVisit();

    // Retry every 30 seconds
    Timer.periodic(
      const Duration(seconds: 30),
      (_) async {

        try {

          await EmployeeLocationService.syncIfInternetAvailable();

          await marketVisitManager.syncOfflineMarketVisit();

          print("Offline Market Visit Sync Completed");

        } catch (e) {

          print("Market Visit Sync Error: $e");

        }
      },
    );

    // ==============================
    // FOREGROUND SERVICE
    // ==============================

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    print("===== MARKET VISIT BACKGROUND SERVICE STARTED =====");

    // ==============================
    // STOP SERVICE
    // ==============================

    service.on("stopService").listen((event) {
      service.stopSelf();
    });

    // ==============================
    // LOCATION SETTINGS
    // ==============================

    final LocationSettings locationSettings =
        Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 5,
                intervalDuration: const Duration(seconds: 5),
              )
            : AppleSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                activityType: ActivityType.fitness,
                distanceFilter: 5,
                pauseLocationUpdatesAutomatically: false,
              );

    // ==============================
    // LOCATION STREAM
    // ==============================

    Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {

        try {

          // ==============================
          // LOCATION ACCURACY
          // ==============================

          if (!position.accuracy.isFinite ||
              position.accuracy < 0 ||
              position.accuracy > 50) {

            print(
              "Skipping inaccurate location: ${position.accuracy}m",
            );

            return;
          }

          print("===== LOCATION UPDATED =====");

          print("LAT: ${position.latitude}");
          print("LNG: ${position.longitude}");

          // ==============================
          // EMPLOYEE LOCATION TRACKING
          // ==============================

          await EmployeeLocationService.sendLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            speed: position.speed >= 0 ? position.speed : null,
            recordAt: position.timestamp.toUtc(),
          );

          print("Employee Location Processing Completed");

          // ==============================
          // GEOFENCE CHECK
          // ==============================

          final inside =
              marketVisitManager.isInsideOffice(position);

          print("Inside Market Geofence: $inside");

          // ==============================
          // MARKET VISIT CREATE
          // ==============================

          if (inside && !wasInsideGeofence) {

            print("===== MARKET VISIT START =====");

            // Update state before API call
            // Prevent duplicate requests
            wasInsideGeofence = true;

            await prefs.setBool(
              insideGeofenceKey,
              true,
            );

            final response =
                await marketVisitManager.createMarketVisit(
              position,
            );

            if (response != null) {

              print(
                "MARKET VISIT RESPONSE: ${response['message']}",
              );

            } else {

              print("MARKET VISIT REQUEST FAILED");

            }

            print("===== MARKET VISIT PROCESSING COMPLETED =====");
          }

          // ==============================
          // EXIT GEOFENCE
          // ==============================

          if (!inside && wasInsideGeofence) {

            print("===== EXITED MARKET GEOFENCE =====");

            wasInsideGeofence = false;

            await prefs.setBool(
              insideGeofenceKey,
              false,
            );

            print("Ready For Next Market Visit");
          }

        } catch (e, stackTrace) {

          print("BACKGROUND LOCATION ERROR: $e");

          print(stackTrace);
        }
      },

      onError: (error) {

        print("LOCATION STREAM ERROR: $error");

      },
    );
  }
}

