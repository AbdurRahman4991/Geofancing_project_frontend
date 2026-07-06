import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/services/attendance_service_api.dart';
import '/helpers/device_helper.dart';
import '/helpers/location_helper.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/location_setting_service.dart';
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}
class _AttendancePageState extends State<AttendancePage> {
  int _selectedIndex = 0;
  bool isInsideOffice = false;
  bool isCheckedIn = false;
  String statusMessage = "Checking location...";
  Position? currentPosition;
  double? officeLatitude;
  double? officeLongitude;
  double? allowedRadius;
  StreamSubscription<Position>? _positionStream;
  bool _isTrackingStarted = false;
  List<dynamic> geofencingList = [];
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }    
      // 🔥 Always latest geofence
  await GeofenceService.syncGeofences();

    String? geoJson = prefs.getString('geofancing');


    if (geoJson != null) {
      geofencingList = jsonDecode(geoJson);
    }

    if (geofencingList.isNotEmpty) {
      await _checkLocationPermission();
    } else {
      if (mounted) {
        setState(() {
          statusMessage = "No geofencing data found!";
        });
      }
    }
  }
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission =
        await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            statusMessage = "Location permission denied";
          });
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          statusMessage =
              "Location permission permanently denied";
        });
      }
      return;
    }
    await _getCurrentLocation();
    _startLocationTracking();
  }
  void _startLocationTracking() {
    if (_isTrackingStarted) return;
    _isTrackingStarted = true;
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 20 meter move হলে update
    );
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;
        setState(() {
          currentPosition = position;
        });
        _checkProximity(position);
      },
      onError: (error) {
        debugPrint("Location Stream Error: $error");
      },
    );
  }
  Future<void> _getCurrentLocation() async {
    Position? position =
        await LocationHelper.getCurrentLocation();
    if (position == null) {
      if (mounted) {
        setState(() {
          statusMessage =
              "⚠️ Unable to get current location";
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      currentPosition = position;
    });
    _checkProximity(position);
  } 
   
  void _checkProximity(Position position) {
    if (geofencingList.isEmpty) {
      setState(() {
        isInsideOffice = false;
        statusMessage = "No geofence found";
      });
      return;
    }

    bool matched = false;

    for (var geofence in geofencingList) {
      double lat = double.parse(geofence['latitude'].toString());
      double lng = double.parse(geofence['longitude'].toString());
      double radius = double.parse(geofence['radius'].toString());

      double distance = Geolocator.distanceBetween(
        lat,
        lng,
        position.latitude,
        position.longitude,
      );

      if (distance <= radius) {
        matched = true;
        break;
      }
    }

    setState(() {
      isInsideOffice = matched;
      statusMessage = matched
          ? "You are inside office area"
          : "You are outside office area";
    });

    if (matched && !isCheckedIn) {
      _checkIn();
    }

    if (!matched && isCheckedIn) {
      _autoCheckOut();
    }
  }
  void _checkIn() async {
    if (!isInsideOffice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You are outside office area",
          ),
        ),
      );
      return;
    }
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Current location not found",
          ),
        ),
      );
      return;
    }
    setState(() {
      statusMessage = "⏳ Checking in...";
    });
    String deviceId =
        await DeviceHelper.getDeviceId();
    final message =
        await AttendanceApiService.checkIn(
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
      deviceId: deviceId,
    );
    if (message.toLowerCase().contains("success")) {
      final service = FlutterBackgroundService();
      service.startService();
      setState(() {
        isCheckedIn = true;
      });
    }
    if (!mounted) return;
    setState(() {
      isCheckedIn =
          message.toLowerCase().contains("success");
      statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  void _autoCheckOut() async {
    if (currentPosition == null) return;
    setState(() {
      statusMessage = "⏳ Checking out...";
    });
    final message =
        await AttendanceApiService.checkOut(
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
    );
    if (message.toLowerCase().contains("success")) {
      final service = FlutterBackgroundService();
      service.invoke("stopService");
      setState(() {
        isCheckedIn = false;
      });
    }
    if (!mounted) return;
    setState(() {
      isCheckedIn = false;
      statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                isInsideOffice
                    ? Icons.location_on
                    : Icons.location_off,
                color: isInsideOffice
                    ? Colors.green
                    : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                currentPosition != null
                    ? "Lat: ${currentPosition!.latitude.toStringAsFixed(5)}\nLng: ${currentPosition!.longitude.toStringAsFixed(5)}"
                    : "Locating...",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _checkIn,
                icon: const Icon(Icons.login),
                label: const Text("Check In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize:
                      const Size(200, 60),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _autoCheckOut,
                icon: const Icon(Icons.logout),
                label: const Text("Check Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent,
                  minimumSize:
                      const Size(200, 60),
                ),
              ),
            ],
          ),
        ),
      ),
      //bottomNavigationBar:
      // BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _selectedIndex = index;
      //     });
      //     if (index == 0) {
      //       Navigator.pushNamed(context, '/');
      //     } else if (index == 1) {
      //       Navigator.pushNamed(
      //         context,
      //         '/profile',
      //       );
      //     }
      //   },
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.settings),
      //       label: 'Settings',
      //     ),
      //   ],
      // ),
    );
  }
}