import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:app_settings/app_settings.dart';

class SystemCheckItem {
  final String title;
  bool status;
  String message;

  SystemCheckItem({
    required this.title,
    this.status = false,
    this.message = "",
  });
}

class SystemCheckPage extends StatefulWidget {
  const SystemCheckPage({super.key});

  @override
  State<SystemCheckPage> createState() => _SystemCheckPageState();
}

class _SystemCheckPageState extends State<SystemCheckPage> {
  bool loading = true;

  bool internet = false;
  bool gpsEnabled = false;
  bool locationPermission = false;
  bool backgroundPermission = false;
  bool notificationPermission = false;
  bool backgroundServiceRunning = false;
  bool batteryOptimization = false;

  String androidVersion = "";
  String appVersion = "";
  String deviceName = "";

  List<SystemCheckItem> checks = [];

  Future<void> fixGps() async {
  await Geolocator.openLocationSettings();
}

Future<void> fixLocationPermission() async {
  await Geolocator.requestPermission();
}

Future<void> fixNotificationPermission() async {
  await permission.Permission.notification.request();
}

Future<void> fixBackgroundPermission() async {
  await Geolocator.openAppSettings();
}

Future<void> startBackgroundService() async {
  await FlutterBackgroundService().startService();
}

Future<void> openAppSettingsPage() async {
  await AppSettings.openAppSettings();
}

  @override
  void initState() {
    super.initState();
    refreshChecks();
  }

  Future<void> refreshChecks() async {
    setState(() {
      loading = true;
    });

    await checkInternet();
    await checkGps();
    await checkLocationPermission();
    await checkNotificationPermission();
    await checkBackgroundService();
    await loadDeviceInfo();

    checks = [
  SystemCheckItem(
    title: "Internet Connection",
    status: internet,
    message: internet ? "Connected" : "No Internet Connection",
  ),

  SystemCheckItem(
    title: "GPS Enabled",
    status: gpsEnabled,
    message: gpsEnabled ? "GPS ON" : "GPS OFF",
  ),

  SystemCheckItem(
    title: "Location Permission",
    status: locationPermission,
    message: locationPermission ? "Granted" : "Not Granted",
  ),

  SystemCheckItem(
    title: "Background Location",
    status: backgroundPermission,
    message: backgroundPermission ? "Allowed" : "Not Allowed",
  ),

  SystemCheckItem(
    title: "Notification Permission",
    status: notificationPermission,
    message: notificationPermission ? "Granted" : "Denied",
  ),

  SystemCheckItem(
    title: "Background Service",
    status: backgroundServiceRunning,
    message: backgroundServiceRunning ? "Running" : "Stopped",
  ),

  SystemCheckItem(
    title: "Battery Optimization",
    status: batteryOptimization,
    message: batteryOptimization ? "Disabled" : "Enabled",
  ),
];

    setState(() {
      loading = false;
    });
  }

  // ========= Part-2 এ এগুলো implement করবো =========

  Future<void> checkInternet() async {
    try {
    final result = await Connectivity().checkConnectivity();

    if (result is List<ConnectivityResult>) {
      internet = result.any((e) => e != ConnectivityResult.none);
    } else {
      internet = result != ConnectivityResult.none;
    }
  } catch (e) {
    internet = false;
  }
  }

  Future<void> checkGps() async {
    try {
    gpsEnabled = await Geolocator.isLocationServiceEnabled();
  } catch (e) {
    gpsEnabled = false;
  }
  }

  Future<void> checkLocationPermission() async {
    try {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    locationPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    backgroundPermission =
        permission == LocationPermission.always;
  } catch (e) {
    locationPermission = false;
    backgroundPermission = false;
  }
  }

  Future<void> checkNotificationPermission() async {
    try {
    if (Platform.isAndroid) {
      final status =
          await permission.Permission.notification.status;

      notificationPermission = status.isGranted;
    } else {
      notificationPermission = true;
    }
  } catch (e) {
    notificationPermission = false;
  }
  }

  Future<void> checkBackgroundService() async {
      try {
    backgroundServiceRunning =
        await FlutterBackgroundService().isRunning();
  } catch (e) {
    backgroundServiceRunning = false;
  }
  }

  Future<void> loadDeviceInfo() async {
      try {
    final packageInfo = await PackageInfo.fromPlatform();

    appVersion =
        "${packageInfo.version} (${packageInfo.buildNumber})";

    if (Platform.isAndroid) {
      AndroidDeviceInfo info =
          await DeviceInfoPlugin().androidInfo;

      deviceName = info.model;
      androidVersion = "Android ${info.version.release}";
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;

      deviceName = info.utsname.machine;
      androidVersion = info.systemVersion;
    }
  } catch (e) {
    deviceName = "Unknown";
    androidVersion = "Unknown";
    appVersion = "Unknown";
  }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("System Check"),
      centerTitle: true,
    ),
    body: loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: refreshChecks,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: checks.length,
              itemBuilder: (context, index) {
                return buildStatusCard(checks[index]);
              },
            ),
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: refreshChecks,
      child: const Icon(Icons.refresh),
    ),
  );
}
Widget buildStatusCard(SystemCheckItem item) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor:
            item.status ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          item.status ? Icons.check : Icons.close,
          color: item.status ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(item.message),

      // 👇 trailing অবশ্যই এখানে থাকবে
      trailing: item.status
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : ElevatedButton(
              onPressed: () async {
                switch (item.title) {
                  case "GPS Enabled":
                    await fixGps();
                    break;

                  case "Location Permission":
                    await fixLocationPermission();
                    break;

                  case "Background Location":
                    await fixBackgroundPermission();
                    break;

                  case "Notification Permission":
                    await fixNotificationPermission();
                    break;

                  case "Background Service":
                    await startBackgroundService();
                    break;

                  default:
                    await openAppSettingsPage();
                }

                await refreshChecks();
              },
              child: const Text("Fix"),
            ),
          ),
  );
}
}
